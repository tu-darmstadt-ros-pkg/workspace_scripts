#!/bin/bash

until rostopic list &>/dev/null ; do sleep 1; done
