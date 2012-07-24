#
# Copyright (c) 2006-2009 National ICT Australia (NICTA), Australia
# Copyright (c) 2004-2009 WINLAB, Rutgers University, USA
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
#
# = stdlib.rb 
#
# == Description
#
# This Ruby file contains various general declarations, which the EC will load 
# before the user's experiment file
#
# These declarations implement the process that loop, check and wait that all 
# the required nodes are UP, before proceeding with the remaining of the 
# experiment
#

# Define some properties that we will use in this 
defProperty('resetDelay', 210,
            "Time to wait before assuming that node didn't boot")
defProperty('resetTries', 1, 
            "Number of reset tries before declaring node dead")
# keeps track of how many times a node has been reset
ResetCount = {}

# 
# This declaration calls the 'everyNS' loop defined in handlerCommand.rb
# This declared bloc will be executed for all the existing node sets ('*') 
# every 10sec. This loop will stop when the bloc returns 'false', which will 
# happen when all the nodes are UP
#
everyNS('*', 10) { |ns|

  if Experiment.prepare?
    false
  else

  # First check if the experiment has not been interrupted
  #exp_status = Experiment.state("status/text()")
  #return true if allEqual(exp_status, "INTERRUPTED")


  # Now check if we are done with adding node in that experiment
  # If not, we skip the checks and loop again in 10sec
  if NodeSet.frozen?
    # Yes, we are done adding nodes...
    nodesDown = []
    nodeCnt = 0
    # For each node in this Node Set, check if it is UP
    # Check that for 'resetDelay' time, if no sucess, reset the node
    # Do only 'resetTries' number of resets before giving up on a node
    ns.eachNode { |n|
      nodeCnt += 1
      if ! n.isUp
        nodesDown << n
        poweredAt = n.poweredAt
        if (poweredAt.kind_of?(Time))
          startupDelay = Time.now - poweredAt
          if (startupDelay > Experiment.property('resetDelay').value)
            count = ResetCount[n] = (ResetCount[n] || 0) + 1
            if (count <= prop.resetTries.value)
              MObject.info('stdlib', "Resetting node ", n)
              n.reset()
            else
              MObject.warn('stdlib', "Giving up on node ", n)
              if NodeHandler.ALLOWMISSING
                Topology.removeNode(n)
                if Topology.empty?
                  MObject.info("stdlib", " ")
                  MObject.info("stdlib", "No resources available for this "+
                               "experiment. Closing the experiment now!" )
                  MObject.info("stdlib", "Please wait and ignore remaining "+
                               "messages...")
                  MObject.info("stdlib", " ")
                  Experiment.close
                end
              else
                MObject.error('stdlib', "One or more nodes failed to check in " +
                  "to your experiment. To ignore and continue, use the '-a'"+
                " flag. Exiting now.")
                Experiment.close
              end
            end
          end
        end
      end
    }
    # Check the number of nodes still not UP...
    nodesDownCnt = nodesDown.length
    if nodesDownCnt > 0
      MObject.info('stdlib', "Waiting for nodes (Up/Down/Total): "+
        "#{nodeCnt-nodesDownCnt}/#{nodesDownCnt}/#{nodeCnt}",
        " - (still down: ", nodesDown[0..2].join(','),")")
    end
    # Check if the experiment is not interrupted
    exp_status = Experiment.state("status/text()")
    if allEqual(exp_status, "INTERRUPTED")
      false 
    else 
      # The experiment is running, stop looping if all the nodes are UP!
      nodesDownCnt > 0
    end
  else
    # We have not finished adding nodes to this experiment, 
    # loop and check again in 10sec
    true
  end
  end
}
