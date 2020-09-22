import os


for i in range(1,21):
    for j in range(0,9):
        filename = "{}.an{}".format(i,j+20)
        print("""(copyfiles
  (help @copyfiles-help)
  (source ("savegame")
  (dest #save)
  (newname "{}")
)
""".format(filename))
