#!/bin/bash
ssh -i ~/.ssh/app-server-db.pem -L 5901:localhost:5901 ubuntu@vncserver
