# coding=utf-8
#############################################################################################
# 程序描述：自动登录远程桌面
# 实现功能：
# 运行周期：
# 创建作者：
# 创建日期：2021-09-29
# 特别注意：需要安装pywin32，比如python2.7需要pywin32-220.win32-py2.7.exe
#############################################################################################
import binascii
import io
import os
import time
# import shlex
# import subprocess
import win32api
import win32crypt

import win32con


############################
# 定义RDP文件中数据内容
############################
def Rdp(username, passwd, rdpFileName, pos):
    print("login: {0} , pos: {1}".format(username, pos))
    pwdHash = win32crypt.CryptProtectData(passwd, u'psw', None, None, None, 0)  # 算出密码Hash值
    pwdHash_ok = binascii.hexlify(pwdHash)
    # print("加密后的密码：" + str(pwdHash_ok))
    # 这个逻辑好像有误，注释掉了
    # str(pwdHash_ok).split("'")[1] # 转换为字符串并使用切割法去掉内容前面的'b'，保留数据本体内容
    str1 = str(pwdHash_ok)
    rdpFileStr = u'''screen mode id:i:1
desktopwidth:i:1440
desktopheight:i:900
session bpp:i:24
winposstr:s:1,1,{pos_ok}
full address:s:10.1.2.199:3389
compression:i:1
keyboardhook:i:2
audiomode:i:0
redirectdrives:i:0
redirectprinters:i:0
redirectcomports:i:0
redirectsmartcards:i:1
displayconnectionbar:i:0
autoreconnection enabled:i:1
username:s:{username_ok}
domain:s:MyDomain
shell working directory:s:
password 51:b:{pwdHash_ok}
disable wallpaper:i:1
disable full window drag:i:1
disable menu anims:i:1
disable themes:i:0
disable cursor setting:i:0
bitmapcachepersistenable:i:1
    '''.format(pos_ok=pos, username_ok=username, pwdHash_ok=str1)
    with io.open(rdpFileName, 'w', encoding='utf-16-le') as f:
        f.write(rdpFileStr)


############################
# 杀掉某个进程
############################
def kill_pid(pid):
    find_kill = 'TASKKILL /F /PID %s' % pid
    print(find_kill)
    # result = os.popen(find_kill)
    # print(result)


############################
# 杀掉所有mstsc进程
############################
def kill_mstsc():
    print("kill all mstsc")
    command = 'TASKKILL /F /IM mstsc.exe'
    print(command)
    os.system(command)


############################
# main
############################
passwd = '123'.encode('utf-16-le')  # 密码
rdpFileName = 'autologin.rdp'  # 设置生成的RDP文件名
# 这两个不要'cf', 'zwq',
names = ['cqx', 'cjh', 'cw', 'cxn', 'fzl', 'ljc', 'ljq', 'lm', 'wbq', 'wenhm', 'wuxueyao', 'yjs', 'yqq', 'zjc', 'zlf', 'zxt', 'zyh', 'bg']
# names = ['cqx', 'cjh']
# 获取屏幕宽度
x = win32api.GetSystemMetrics(win32con.SM_CXSCREEN)
# 获取屏幕高度
y = win32api.GetSystemMetrics(win32con.SM_CYSCREEN)
print("x = {0} , y = {1}".format(x, y))
# 窗口高度
windows_high = 200
# 计算一行几个
row = x / windows_high
# 计算最多几列
column = y / windows_high
print("row = {0} , column = {1}".format(row, column))
row_num = 0
column_num = 0
i = 0
j = 0
for name in names:
    iz = i + windows_high
    jz = j + windows_high
    pos = "{_i},{_j},{_iz},{_jz}".format(_i=i, _j=j, _iz=iz, _jz=jz)
    Rdp(name, passwd, rdpFileName, pos)  # 生成Rdp
    os.system("mstsc ./autologin.rdp /console /v: 10.1.2.199:3389")  # 调用CMD命令运行远程桌面程序
    # 休眠30秒，等待窗口完成登录操作
    time.sleep(30)
    # 杀掉mstsc进程
    kill_mstsc()
    # args = shlex.split("mstsc ./111.rdp /console /v: 10.1.2.199:3389")
    # p = subprocess.Popen(args)
    # p.pid #这里取到的pid不正确
    i = i + windows_high
    row_num = row_num + 1
    if row_num >= row:
        i = 0
        row_num = 0
        j = j + windows_high
        column_num = column_num + 1
        if column_num >= column:
            j = 0
            column_num = 0
# 杀掉所有的mstsc进程
#kill_mstsc()

############################
# 配置说明
############################
# alternate shell:s:{route} #初始化启动程序
# password 51:b:{pwdHash_ok} #密钥
# domain:s:MyDomain   #域名
# username:s:cqx #用户名
# screen mode id:i:1 #(显示方式，1代表窗口显示，2代表全屏显示)
# desktopwidth:i:1440 #(远程桌面的实际宽度)
# desktopheight:i:900 #(远程桌面的实际高度)
# winposstr:s:1,1,800,200,1000,400 #（远程桌面的显示位置（后4个参数）：水平方向从位置800到1000，垂直方向从200到400）

############################
# 如果需要启动的时候做点什么
############################
# format(route=route)
# route ='C:\Documents and Settings\Administrator\桌面\Rentor\批处理.bat'  #设置初始化启动程序
