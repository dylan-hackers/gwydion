module: hello
use-libraries: common-dylan, io, duim-core, gtk2-duim
use-modules: common-dylan, format-out, duim

define frame <hello-frame> (<simple-frame>)
end;

make(<hello-frame>);