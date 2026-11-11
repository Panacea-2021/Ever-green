const http = require('http');
const fs = require('fs');
const path = require('path');
const file = 'D:\\EG\\Evergreen_frontend\\build\\app\\outputs\\flutter-apk\\app-release.apk';
const server = http.createServer((req, res) => {
  const stat = fs.statSync(file);
  res.writeHead(200, {
    'Content-Type': 'application/vnd.android.package-archive',
    'Content-Length': stat.size,
    'Content-Disposition': 'attachment; filename="app-release.apk"',
  });
  fs.createReadStream(file).pipe(res);
});
server.listen(8081, '0.0.0.0', () => console.log('Serving APK on http://0.0.0.0:8081/app-release.apk'));
