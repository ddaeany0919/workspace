Must added into the ${HOME}/.bashrc
<pre>
if [ -z ${LC_WORKSPACE_PROJECT} ]; then
    case $- in
        *i*) ;;
        *)
        return;;
    esac
fi
</pre>

source ~/workspace/bin/.bashrc_luis

# install the logcat-color
pip install --break-system-packages etc/logcat-color/logcat-color-0.10.0.tar.gz
