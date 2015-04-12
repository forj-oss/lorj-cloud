#!/usr/bin/env ruby
# encoding: UTF-8

# (c) Copyright 2014 Hewlett-Packard Development Company, L.P.
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.

# It requires Core objects to be defined + default ForjProcess functions.

# Common definition
class Lorj::BaseDefinition # rubocop: disable Style/ClassAndModuleChildren
  # All objects used by this process are built from a Controller
  process_default :use_controller => true
end

# Class to manage retry on errors before failing
class SSLErrorMgt
  def initialize(iMaxRetry = 5)
    @retry = 0
    @max_retry = iMaxRetry
  end

  def wait(message, issue = nil)
    if @retry < @max_retry
      sleep(2)
      @retry += 1
      if PrcLib.level == 0
        msg = format('%s/%s try... ', @retry, @max_retry)
        msg += issue unless issue.nil?
        print msg
      end
      return false
    else
      PrcLib.error('Too many retry. %s', message)
      return true
    end
  end

  def error_detected(message, backtrace, e)
    if message.match('SSLv2/v3 read server hello A: unknown protocol')
      return wait(message, "'unknown protocol' SSL Error")
    elsif e.is_a?(Excon::Errors::InternalServerError)
      return wait(message, ANSI.red(e.class))
    else
      PrcLib.error("Exception %s: %s\n%s", e.class, message,
                   backtrace.join("\n"))
      return true
    end
  end
end
