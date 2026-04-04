
set workspace=%1
set script=%2
set parameters=%3
wsl -u luis cd ~/; source ~/workspace/bin/.bashrc_luis ; workspace %workspace% ; %script% %parameters%