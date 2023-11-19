from PIL import Image
from math import sqrt

img = Image.open("VGA_palette_with_black_borders.png")
img = img.convert("RGB")
pix = img.load()

color_list = []

for j in range(img.height):
    for i in range(img.width):
        color_list.append(pix[i, j])


def find_near_color(color):
    global color_list
    if (color[0] == 255 and color[1] == 255 and color[2] == 255):
        return 0
    near = 1000
    color_sel = 0
    for c in color_list:
        dist = pow(color[0] - c[0], 2)
        dist += pow(color[1] - c[1], 2)
        dist += pow(color[2] - c[2], 2)
        dist = sqrt(dist)
        if dist < near:
            # print("near: {:^5.2f} dist {:^5.2f} color {:^5} ({:^4}, {:^4}, {:^4}) O: ({:^4}, {:^4}, {:^4})".format(near, dist, color_sel, c[0], c[1], c[2], color[0], color[1], color[2]))
            near = dist
            color_sel = color_list.index(c)

    # print("****************************")
    return color_sel


def transform_image(img_pix, w, h):
    pal_color = []
    for j in range(h):
        for i in range(w):
            pal_color.append(find_near_color(img_pix[i, j]))
    return pal_color


def write_new_image(img_name):
    global color_list
    img = Image.open(img_name)
    img = img.convert("RGB")
    pix = img.load()
    data_raw = transform_image(pix, img.width, img.height)
    data = [img.width, img.height] + data_raw
    dest_name = img_name.replace(".png", ".img")
    f = open(dest_name, "wb")
    f.write(bytearray(data))
    f.close()
    img_res = Image.new("RGB", (img.width, img.height))
    pix_res = img_res.load()
    c = 0
    for j in range(img.height):
        for i in range(img.width):
            pix_res[i, j] = color_list[data_raw[c]]
            c += 1
    img_res.show()
    # print(data)
write_new_image("meteorGrey.png")
