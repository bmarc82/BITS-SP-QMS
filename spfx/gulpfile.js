'use strict';

const build = require('@microsoft/sp-build-web');

build.addSuppression(
  /Warning - \[sass\] Node Sass does not yet support your current environment/
);

const getTasks = build.rig.getTasks;
build.rig.getTasks = function () {
  const result = getTasks.call(build.rig);
  result.set('serve', result.get('serve-deprecated'));
  return result;
};

build.initialize(require('gulp'));
