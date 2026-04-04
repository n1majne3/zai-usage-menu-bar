#!/usr/bin/env node

import https from 'https';

const authToken = process.argv[2];

if (!authToken) {
  console.error('Usage: node test-api.mjs <auth-token>');
  process.exit(1);
}

const endpoints = [
  'https://open.bigmodel.cn/api/monitor/usage/model-usage',
  'https://open.bigmodel.cn/api/monitor/usage/tool-usage',
  'https://open.bigmodel.cn/api/monitor/usage/quota/limit'
];

const now = new Date();
const startDate = new Date(now.getFullYear(), now.getMonth(), now.getDate() - 1, now.getHours(), 0, 0, 0);
const endDate = new Date(now.getFullYear(), now.getMonth(), now.getDate(), now.getHours(), 59, 59, 999);

const formatDateTime = (date) => {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  const hours = String(date.getHours()).padStart(2, '0');
  const minutes = String(date.getMinutes()).padStart(2, '0');
  const seconds = String(date.getSeconds()).padStart(2, '0');
  return `${year}-${month}-${day} ${hours}:${minutes}:${seconds}`;
};

const startTime = formatDateTime(startDate);
const endTime = formatDateTime(endDate);

async function fetchEndpoint(url, withParams = true) {
  return new Promise((resolve, reject) => {
    let fullUrl = url;
    if (withParams) {
      fullUrl += `?startTime=${encodeURIComponent(startTime)}&endTime=${encodeURIComponent(endTime)}`;
    }
    
    const parsedUrl = new URL(fullUrl);
    const options = {
      hostname: parsedUrl.hostname,
      port: 443,
      path: parsedUrl.pathname + parsedUrl.search,
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${authToken}`,
        'Accept-Language': 'en-US,en',
        'Content-Type': 'application/json'
      }
    };

    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => { data += chunk; });
      res.on('end', () => {
        console.log(`\n=== ${url} (Status: ${res.statusCode}) ===`);
        try {
          const json = JSON.parse(data);
          console.log(JSON.stringify(json, null, 2));
        } catch {
          console.log(data);
        }
        resolve();
      });
    });

    req.on('error', reject);
    req.end();
  });
}

async function run() {
  for (const url of endpoints) {
    await fetchEndpoint(url, !url.includes('quota'));
  }
}

run().catch(console.error);
