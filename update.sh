hexo build

git add .
git commit -m  "$1"
git push -f --set-upstream origin master

echo "上传完毕"