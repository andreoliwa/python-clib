#!/bin/bash
dpkg --get-selections | grep $* | cut -f 1