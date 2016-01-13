#!/usr/bin/env python

"""
Usage:
    anrunner.py PATTERN MODULE ARGS
"""

import docopt
import ansible.runner
import json


def ansibleRunner(pattern, module_name, module_args, **kwargs):
    runner1 = ansible.runner.Runner(
            sudo=True,
            timeout=10,
            forks=1,

            module_name  = module_name,
            module_args  = module_args,
            host_list    = [pattern],

            remote_user='etstaff',
            remote_pass='t1w@mfnT!',
            sudo_pass='t1w@mfnT!',

            **kwargs
            )
    run_result = runner1.run()

    # try with alternate credentials if not sucessfull
    if run_result['dark'] != {}:
        runner2 = ansible.runner.Runner(
                sudo=True,
                timeout=10,
                forks=1,

                module_name  = module_name,
                module_args  = module_args,
                host_list    = [pattern],

                remote_user='etapp',
                private_key_file='/home/zsolt/.ssh/etapp_id_rsa',

                **kwargs
                )
        run_result = runner2.run()

    return run_result



if __name__ == "__main__":
    arguments = docopt.docopt(__doc__)
    res = ansibleRunner(arguments['PATTERN'], arguments['MODULE'], arguments['ARGS'])
    print json.dumps(res) 

