1. 修改commit的committer信息
git config --global user.name "Your Name"
git config --global user.email you@example.com
git commit --amend --reset-author

2. git拉取远程分支到本地
git checkout -b demo origin/demo
// 如果遇上错误“... is not a commit and a branch ...”，则可先执行如下命令后重试
git fetch 远程仓库地址

3. 服务器上git仓库的拉取方式：
$ git remote  -v
tmp     ssh://root@192.168.132.11/root/envoy/tmp/envoy.git (fetch)
tmp     ssh://root@192.168.132.11/root/envoy/tmp/envoy.git (push)

4. 将一个git仓库变为可推送：
cd repo
mv .git ../repo.git # renaming just for clarity
cd ..
rm -fr repo
cd repo.git
git config --bool core.bare true

5. 查看某个commit id存在于哪些branch上
git branch -r --contains commitid

6. 取消代理配置及安全认证
git config --global --unset http.proxy
git config --global --unset https.proxy
git config --global http.sslVerify false

7. 修改commit的作者
git commit --amend --author="NewAuthor <NewEmail@address.com>"
git commit --amend --author="Author <Email@address.com>"
git commit --amend --author="Author <Email@address.com>"

8.拉取repo的所有tag
git fetch --tags

9. 修改上一个commit为当前时间
git commit --amend --date="$(date -R)"

10. 查看包含author和committer信息的log
git log --pretty=full

11. git删除untracked文件
git clean -d -f

12. git只添加tracked文件
git add -u
