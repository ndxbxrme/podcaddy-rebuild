@echo off
call curl --data "key=%CLOUDINARY_SECRET%" http://localhost:23232/maintenance-on
timeout 10
call curl --form "podcaddyDatabase=@%1" --form "key=%CLOUDINARY_SECRET%" http://localhost:23232/api/upload/database