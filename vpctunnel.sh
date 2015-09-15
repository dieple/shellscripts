#!/bin/bash
#ssh -f -L some_port:private_machine:22 user@gateway "sleep 10" && ssh -p some_port private_user@localhost

ssh -i ~/.ssh/app-server-db.pem -L 9999:10.0.1.34:80 ec2-user@54.88.68.116
