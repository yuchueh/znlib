@echo off
echo ####################################
echo #                                  #
echo #    清除所有目录下的无效文件      #
echo #         只处理归档属性           #
echo #                                  #
echo ####################################

del /S /A:A *.~*;*.dcu;*.stat;*.ddp;*.bak;*.exe;*.local;*.identcache
