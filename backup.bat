@echo off
call curl --data "key=%CLOUDINARY_SECRET%" http://localhost:23232/maintenance-on
timeout 10
call curl --data "key=%CLOUDINARY_SECRET%" http://localhost:23232/api/getdb > backup/podcaddy_%date:~-4,4%%date:~-10,2%%date:~-7,2%.json
call curl --data "key=%CLOUDINARY_SECRET%" http://localhost:23232/maintenance-off
