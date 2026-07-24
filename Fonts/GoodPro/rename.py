import os
fpath = "Fonts/GoodPro"
for fname in os.listdir(fpath):
    if fname[-4:] != ".otf":
        continue
    if "GoodPro-" in fname:
        continue
    try:
        name = ""
        with open(fpath + "/" + fname, "rb") as fs:
            text = fs.read()
            name = text.split(b"GoodPro-")[1]
            name = name.split(b":")[0]
            os.rename(fpath + "/" + fname, fpath + "/" + "GoodPro-" + name.decode("utf-8") + ".otf")
            print(name)
    except Exception as e:
        print(fname, e)