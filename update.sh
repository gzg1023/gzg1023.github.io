echo "开始打包"


hexo generate

echo "开始上传"

git add .
git commit -m  "$1"
git push -f --set-upstream origin master

echo "上传完毕"