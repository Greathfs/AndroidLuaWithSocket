--基本方法  
print("您现在使用的是LUA脚本语言")  
print("让我们一起来感受它的奇妙吧!\n")  
  
--特点1,赋值  
a={1,2}  
b=a  
print(a==b, a~=b)    --输出 true, false  
a={1,2}  
b={1,2}  
print(a==b, a~=b)    --输出 false, true  
  
--特点2,交换  
a,b=1,2  
a,b=b,a  
print(a)  
print(b)  
  
print("连接".."字符串"..2^3)  
print(type(2))  
  
--while循环  
i=0  
print("while循环例子")  
while i<5  
do   
print(i);  
i=i+1   
end  
  
--repeat循环  
i=0  
print("repeat循环例子")  
repeat  
print(i)  
i=i+1  
until i>=5  
  
--for循环  
print("for循环例子")  
for i=0,5,1  
do  
print(i)  
end  
  
T1={}  
T1[1] = 10  
print(T1[1])  
  
function fun(a,b,...)  
print(a)  
print(b)  
print(arg[1])  
print(arg[2])  
print(arg[3])  
return  
end  
  
a,b=2,3  
fun(a,b,200,400,500)  