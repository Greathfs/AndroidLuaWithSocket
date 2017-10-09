---[[
local p = package.loadlib("C:\\pipe.dll","luaopen_Pipe")

if(p)then
  p()
  print("OK")
else
  print("Error")
  -- Error
end
---
cmd=Pipe.runcmd

c=cmd( "ping www.eben.cn")
print(c)

d=cmd("dir")
print(d)

e=cmd("ipconfig")
print (e)