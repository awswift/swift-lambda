"use strict";
var childProcess = require('child_process');

exports.handler = function(event, context, callback) {
    process.env['PATH'] += ':' + process.env['LAMBDA_TASK_ROOT'];
    process.env['LD_LIBRARY_PATH'] = process.env['LAMBDA_TASK_ROOT'];

    let input = { event: event, context: context };
    let child = childProcess.spawnSync('./swiftLambdaEntrypoint', [], {
        input: JSON.stringify(input)
    });

    let output = JSON.parse(child.stdout);
    console.log(output);
    callback(null, output);
};
