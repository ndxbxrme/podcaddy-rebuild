(function() {
  var dateNow, fs, i, item, j, json, k, len, len1, len2, pod, pods, ref, sitem, sub, subs, txt;

  fs = require('fs');

  txt = fs.readFileSync('./data/pods.json', 'utf-8');

  txt = txt.replace(/.*CONTROL.*/, '');

  txt = txt.replace(/ObjectId\("(.*)?"\)/g, '"$1"');

  txt = txt.replace(/ISODate\("(.*)?"\)/g, function(all, capture) {
    return new Date(capture).valueOf();
  });

  json = JSON.parse(txt);

  dateNow = new Date().setHours(new Date().getHours() - 2).valueOf();

  pods = [];

  for (i = 0, len = json.length; i < len; i++) {
    item = json[i];
    pod = {
      _id: item._id,
      title: item.title,
      slug: item.titleSlug,
      description: item.description,
      url: item.url,
      link: item.link,
      image: item.image,
      imageUrl: item.cloudinary.secure_url,
      categories: item.categories,
      pubDate: item.pubDate,
      updated: dateNow
    };
    pods.push(pod);
  }

  subs = [];

  for (j = 0, len1 = json.length; j < len1; j++) {
    item = json[j];
    ref = item.subscribers;
    for (k = 0, len2 = ref.length; k < len2; k++) {
      sitem = ref[k];
      sub = {
        pid: item._id,
        uid: sitem.userId,
        d: sitem.date
      };
      subs.push(sub);
    }
  }

  fs.writeFileSync('./data/pods_processed.json', JSON.stringify(pods), 'utf-8');

  fs.writeFileSync('./data/subs_processed.json', JSON.stringify(subs), 'utf-8');

  console.log(JSON.stringify(pods).substring(0, 2000));

}).call(this);

//# sourceMappingURL=update.js.map
