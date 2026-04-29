#!/usr/bin/env python
import os
import subprocess
# 加载 godot-cpp
env = SConscript('godot-cpp/SConstruct')

env.Append(CPPPATH=[
  'godot-cpp/include',
  'godot-cpp/gen/include'
])

lib = None

# 添加源码（用 Glob）
sources = Glob('ios/src/*.cpp') + Glob('ios/src/*.mm')

platform = env['platform']
ios = platform == 'ios'
macos = platform == 'macos'

if macos:
  sdk = '/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk'

  env.Append(CPPFLAGS=[
    '-isysroot', sdk
  ])

  env.Append(LINKFLAGS=[
    '-lobjc',
    '-framework', 'AppKit',
    '-framework', 'Foundation',
    '-framework', 'AuthenticationServices',
    '-framework', 'SafariServices'
  ])
  lib = env.SharedLibrary(
    target='bin/libone',
    source=sources,
  )

Default(lib)
