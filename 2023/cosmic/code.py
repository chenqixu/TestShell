# coding=utf-8
#############################################################################################
# 程序描述：中文编码测试
# 实现功能：
# 运行周期：
# 创建作者：
# 创建日期：2023-06-07
# 特别注意：
#############################################################################################

import sys
reload(sys)
sys.setdefaultencoding('utf-8')
print(sys.getdefaultencoding())

s='汉字'
print(s,type(s))
s0=s.encode()
print(s0,type(s0))
s1=s0.decode()
print(s1,type(s1))
s2=s.encode('utf-8')
print(s2,type(s2))
s3=s.encode('gbk')
print(s3,type(s3))
s4=s2.decode('utf-8')
print(s4,type(s4))
s5=s3.decode('gbk')
print(s5,type(s5))