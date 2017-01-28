"use strict";
var childProcess = require('child_process');
var fs = require('fs');
let AWS = require('aws-sdk');

exports.handler = function(event, context, callback) {
    let libsDir = '/tmp/swiftLambdaLibs';
    let loader = libsDir + '/ld-linux-x86-64.so.2'; 

    let runIt = function() {
        let input = { event: event, context: context };
        let child = childProcess.spawnSync(loader, ['--library-path', libsDir, './swiftLambdaEntrypoint'], {
            input: JSON.stringify(input)
        });

        let output = JSON.parse(child.stdout);
        console.log(output);
        callback(null, output);
    };

    if (fs.existsSync(loader)) {
        runIt();
    } else {
        let s3 = new AWS.S3();
        let zipPath = '/tmp/swiftLambdaLibs.zip';
        let libsZipFileStream = fs.createWriteStream(zipPath);
        
        libsZipFileStream.on('close', function() {
            let child = childProcess.spawnSync('unzip', [zipPath, '-d', libsDir]);
            runIt();
        });

        let params = { 
            Bucket: process.env.SWIFTLAMBDA_LIBS_BUCKET, 
            Key: process.env.SWIFTLAMBDA_LIBS_KEY 
        };

        s3.getObject(params).createReadStream().pipe(libsZipFileStream);
    }
};
