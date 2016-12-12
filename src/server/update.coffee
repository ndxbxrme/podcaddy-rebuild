fs = require 'fs'
txt = fs.readFileSync './data/pods.json', 'utf-8'
txt = txt.replace /.*CONTROL.*/, ''
txt = txt.replace /ObjectId\("(.*)?"\)/g, '"$1"'
txt = txt.replace /ISODate\("(.*)?"\)/g, (all, capture) ->
  new Date(capture).valueOf()
json = JSON.parse txt
dateNow = new Date().setHours(new Date().getHours() - 2).valueOf()
pods = []
for item in json
  pod = 
    _id: item._id
    title: item.title
    slug: item.titleSlug
    description: item.description
    url: item.url
    link: item.link
    image: item.image
    imageUrl: item.cloudinary.secure_url
    categories: item.categories
    pubDate: item.pubDate
    updated: dateNow
  pods.push pod
subs = []
for item in json
  for sitem in item.subscribers
    sub = 
      pid: item._id
      uid: sitem.userId
      d: sitem.date
    subs.push sub
fs.writeFileSync './data/pods_processed.json', JSON.stringify(pods), 'utf-8'
fs.writeFileSync './data/subs_processed.json', JSON.stringify(subs), 'utf-8'
console.log JSON.stringify(pods).substring 0, 2000