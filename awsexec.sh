#!/bin/bash

aws ecs execute-command --cluster platform-training-cluster --task 8d91482a170049b39b1e253612542375 --container platform-training-app --interactive --command "/bin/bash"
