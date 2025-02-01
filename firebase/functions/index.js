const dbRoot = "openai";
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { onSchedule } = require('firebase-functions/v2/scheduler');
const {onRequest} = require("firebase-functions/v2/https");
const {getDatabase} = require("firebase-admin/database");
const axios = require("axios");
admin.initializeApp();
const db = getDatabase();

async function getData(path) {
   const snapshot = await db.ref(path).get();
   return snapshot.val();
}  

async function increment(path,value) {
  console.log("increment "+path+" by "+value);
  const ref = db.ref(path);
  await ref.transaction((currentValue)=>{
    return (currentValue||0) + value;
  });
  console.log("increment done");
}  

function reply(res,data,status) {
  res.setHeader("Content-Type","application/json");
  res.status(status?status:200).send(JSON.stringify(data));
}

function getDailyUsageReset() {
  const now = new Date(); // Current time
  const millisInDay = 24 * 3600 * 1000; // Total milliseconds in a day
  const millisSinceMidnight = now.getTime() % millisInDay;
  const millisToMidnight = millisInDay - millisSinceMidnight;
  return millisToMidnight;
}

function getMonthlyUsageReset() {
  const now = new Date(); // Current time
  const currentYear = now.getUTCFullYear();
  const currentMonth = now.getUTCMonth(); // 0-indexed month (0 = January, 11 = December)
  const firstOfNextMonth = new Date(Date.UTC(
    currentYear,
    currentMonth + 1,
    1, 0, 0, 0));
  const millisToFirst = firstOfNextMonth - now;
  return millisToFirst;
}

async function enforceLimits(userId,resData,res,payload) {
    const limits = await getData(dbRoot+"/limits");
    if(limits.maxPayloadSize) {
        const payloadSize = JSON.stringify(payload).length;
        if(payloadSize>limits.maxPayloadSize) {
            resData.error = {c:10,m:"The payload is too large: "+payloadSize+" characters, maximum allowed: "+limits.maxPayloadSize};
            reply(res,resData,403);
            return false;
        }
    }
    var usage = await getData(dbRoot+"/usage/"+userId);
    if(!usage) usage = {daily:0,monthly:0};
    resData.usage = usage;
    resData.limits = limits;
    resData.usage.resetDaily = getDailyUsageReset();
    resData.usage.resetMonthly = getMonthlyUsageReset();
    if(limits.daily && usage.daily>=limits.daily) {
        resData.error = {c:11,m:"Daily usage limit reached. It will be reset in "+getDailyUsageReset()};
        reply(res,resData,403);
        return false;
    }
    if(limits.monthly && usage.monthly>=limits.monthly) {
        resData.error={c:12,m:"Monthly usage limit reached. It will be reset in "+getMonthlyUsageReset()};
        reply(res,resData,403);
        return false;
    }
    return true; // OK to proceed
}

async function doApiCall(urlPath,payload) {
    if(!urlPath.startsWith("/")) urlPath = "/"+urlPath;
    const apiKey = await getData(dbRoot+"/apiKey");
    const config = await getData(dbRoot+"/config");
    const copyPayload = Object.assign({},payload);
    const actualPayload = Object.assign(copyPayload,config);
    const openaiResponse = await axios.post(
        "https://api.openai.com"+urlPath,
         actualPayload,
         {
            headers: {
                Authorization: `Bearer ${apiKey}`,
                "Content-Type": "application/json",
            },
         }
    );
    return openaiResponse;
}

async function processRequest(req,res,token) {
    const userId = token.uid;
    console.log("userId="+userId);
    try {
        const inData = JSON.parse(req.rawBody);
        const payload = inData.payload;
        if(!payload) {
          return reply(res,{error:{c:5,m:"Missing payload"}},401);
        }
        const resData = {};
        if(!await enforceLimits(userId,resData,res,payload)) return;
        var urlPath = inData.urlPath;
        if(!urlPath) {
          return reply(res,{error:{c:4,m:"Missing urlPath"}},401);
        }
        const openaiResponse = await doApiCall(urlPath,payload);
        const usedTokens = openaiResponse.data?.usage?.total_tokens ?? 0;
        console.log("Used tokens: "+usedTokens);
        if(usedTokens) {
          resData.usage.daily += usedTokens;
          resData.usage.monthly += usedTokens;
          await increment(dbRoot+"/usage/"+userId+"/daily",usedTokens);
          await increment(dbRoot+"/usage/"+userId+"/monthly",usedTokens);
        }
        resData.result = openaiResponse.data ?? null;
        reply(res,resData);
    }
    catch (error) {
        console.error("Error: ", error);
        reply(res,{error:{c:101,m:"Internal Server Error: "+error}},501);
    }
}

exports.callOpenAI = onRequest(async (req, res) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return reply(res,{error:{c:1,m:"Missing auth token"}},403);
    }
    const idToken = authHeader.split('Bearer ')[1];
    var decodedToken;
    try {
      decodedToken = await admin.auth().verifyIdToken(idToken);
    }
    catch (error) {
      console.error('Error verifying token: ', error);
      return reply(res,{error:{c:2,m:"Unauthorized: Invalid token"}},403);
    }
    await processRequest(req,res,decodedToken);
  }
  catch(err) {
    console.log("err="+err);
    return reply(res,{error:{c:3,m:""+err}},401);
  }
});

// Reset daily usage at 0:0 GMT every day
exports.resetDailyUsage = onSchedule(
  {schedule:"0 0 * * *",timeZone:"GMT"},
  async (event) => {
    const path = dbRoot+'/usage';
    const usageData = await getData(path);
    const updates = {};
    Object.keys(usageData || {}).forEach(userId => {
      updates[`${userId}/daily`] = 0;
    });
    await db.ref(path).update(updates);
    console.log('Daily usage reset');
  });

// Reset monthly usage on the 1st at 0:0 GMT
exports.resetMonthlyUsage = onSchedule(
  {schedule:"0 0 1 * *",timeZone:"GMT"},
  async (event) => {
    await db.ref(dbRoot+"/usage").remove();
    console.log('Monthly usage reset');
  });
