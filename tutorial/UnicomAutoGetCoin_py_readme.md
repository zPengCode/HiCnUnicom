### UnicomGetCoin.py
作者： https://github.com/QiuYueBaiJXW

#联通营业厅签到领积分
#新增七日4GB流量包获取


#使用方法

  一、自己挂服务器

        只需下载py文件，将py文件倒数第二行引号中的内容按照提示抓包替换即可。
  
  ~~二、利用github的workflow自动运行~~

   ~~首先fork该项目，然后按照 “一、”中的操作抓包修改py文件~~
  
   ~~接着前往.github/workflows/AutoRun.yml文件中第26行的网址改为你fork之后的git网址~~
   
   如需使用该方法，请前往https://github.com/QiuYueBaiJXW
 
 #抓包方法及内容
    
    开启抓包软件，登录手机营业厅
    
    查找网址为 https://m.client.10010.com/mobileService/login.htm 的记录，找到请求内容将reqtime后面的内容按要求填入py文件。
    
 #无限期To Do
 
     1.每日自动抽奖三次
     
     2.改进登录方式，取消抓包登录，改用账号密码登录
     
     3.sh版本的其他功能比如沃之树等等
 
 #感谢
    
    @mixool
    
    感谢@mixool将py版本纳入其中，sh版本的其他功能列入无限期 To do
    
  #免责申明
    
    该项目仅供学习使用，严禁用于商业用途，由此造成的一切后果，本人概不负责。
