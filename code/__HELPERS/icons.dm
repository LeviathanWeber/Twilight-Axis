/*
IconProcs README

A BYOND library for manipulating icons and colors

by Lummox JR

version 1.0

The IconProcs library was made to make a lot of common icon operations much easier. BYOND's icon manipulation
routines are very capable but some of the advanced capabilities like using alpha transparency can be unintuitive to beginners.

CHANGING ICONS

Several new procs have been added to the /icon datum to simplify working with icons. To use them,
remember you first need to setup an /icon var like so:

GLOBAL_DATUM_INIT(my_icon, /icon, new('iconfile.dmi'))

icon/ChangeOpacity(amount = 1)
    A very common operation in DM is to try to make an icon more or less transparent. Making an icon more
    transparent is usually much easier than making it less so, however. This proc basically is a frontend
    for MapColors() which can change opacity any way you like, in much the same way that SetIntensity()
    can make an icon lighter or darker. If amount is 0.5, the opacity of the icon will be cut in half.
    If amount is 2, opacity is doubled and anything more than half-opaque will become fully opaque.
icon/GrayScale()
    Converts the icon to grayscale instead of a fully colored icon. Alpha values are left intact.
icon/ColorTone(tone)
    Similar to GrayScale(), this proc converts the icon to a range of black -> tone -> white, where tone is an
    RGB color (its alpha is ignored). This can be used to create a sepia tone or similar effect.
    See also the global ColorTone() proc.
icon/MinColors(icon)
    The icon is blended with a second icon where the minimum of each RGB pixel is the result.
    Transparency may increase, as if the icons were blended with ICON_ADD. You may supply a color in place of an icon.
icon/MaxColors(icon)
    The icon is blended with a second icon where the maximum of each RGB pixel is the result.
    Opacity may increase, as if the icons were blended with ICON_OR. You may supply a color in place of an icon.
icon/Opaque(background = "#000000")
    All alpha values are set to 255 throughout the icon. Transparent pixels become black, or whatever background color you specify.
icon/BecomeAlphaMask()
    You can convert a simple grayscale icon into an alpha mask to use with other icons very easily with this proc.
    The black parts become transparent, the white parts stay white, and anything in between becomes a translucent shade of white.
icon/AddAlphaMask(mask)
    The alpha values of the mask icon will be blended with the current icon. Anywhere the mask is opaque,
    the current icon is untouched. Anywhere the mask is transparent, the current icon becomes transparent.
    Where the mask is translucent, the current icon becomes more transparent.
icon/UseAlphaMask(mask, mode)
    Sometimes you may want to take the alpha values from one icon and use them on a different icon.
    This proc will do that. Just supply the icon whose alpha mask you want to use, and src will change
    so it has the same colors as before but uses the mask for opacity.

COLOR MANAGEMENT AND HSV

RGB isn't the only way to represent color. Sometimes it's more useful to work with a model called HSV, which stands for hue, saturation, and value.

    * The hue of a color describes where it is along the color wheel. It goes from red to yellow to green to
    cyan to blue to magenta and back to red.
    * The saturation of a color is how much color is in it. A color with low saturation will be more gray,
    and with no saturation at all it is a shade of gray.
    * The value of a color determines how bright it is. A high-value color is vivid, moderate value is dark,
    and no value at all is black.

Just as BYOND uses "#rrggbb" to represent RGB values, a similar format is used for HSV: "#hhhssvv". The hue is three
hex digits because it ranges from 0 to 0x5FF.

    * 0 to 0xFF - red to yellow
    * 0x100 to 0x1FF - yellow to green
    * 0x200 to 0x2FF - green to cyan
    * 0x300 to 0x3FF - cyan to blue
    * 0x400 to 0x4FF - blue to magenta
    * 0x500 to 0x5FF - magenta to red

Knowing this, you can figure out that red is "#000ffff" in HSV format, which is hue 0 (red), saturation 255 (as colorful as possible),
value 255 (as bright as possible). Green is "#200ffff" and blue is "#400ffff".

More than one HSV color can match the same RGB color.

Here are some procs you can use for color management:

ReadRGB(rgb)
    Takes an RGB string like "#ffaa55" and converts it to a list such as list(255,170,85). If an RGBA format is used
    that includes alpha, the list will have a fourth item for the alpha value.
hsv(hue, sat, val, apha)
    Counterpart to rgb(), this takes the values you input and converts them to a string in "#hhhssvv" or "#hhhssvvaa"
    format. Alpha is not included in the result if null.
ReadHSV(rgb)
    Takes an HSV string like "#100FF80" and converts it to a list such as list(256,255,128). If an HSVA format is used that
    includes alpha, the list will have a fourth item for the alpha value.
RGBtoHSV(rgb)
    Takes an RGB or RGBA string like "#ffaa55" and converts it into an HSV or HSVA color such as "#080aaff".
HSVtoRGB(hsv)
    Takes an HSV or HSVA string like "#080aaff" and converts it into an RGB or RGBA color such as "#ff55aa".
BlendRGB(rgb1, rgb2, amount)
    Blends between two RGB or RGBA colors using regular RGB blending. If amount is 0, the first color is the result;
    if 1, the second color is the result. 0.5 produces an average of the two. Values outside the 0 to 1 range are allowed as well.
    The returned value is an RGB or RGBA color.
BlendHSV(hsv1, hsv2, amount)
    Blends between two HSV or HSVA colors using HSV blending, which tends to produce nicer results than regular RGB
    blending because the brightness of the color is left intact. If amount is 0, the first color is the result; if 1,
    the second color is the result. 0.5 produces an average of the two. Values outside the 0 to 1 range are allowed as well.
    The returned value is an HSV or HSVA color.
BlendRGBasHSV(rgb1, rgb2, amount)
    Like BlendHSV(), but the colors used and the return value are RGB or RGBA colors. The blending is done in HSV form.
HueToAngle(hue)
    Converts a hue to an angle range of 0 to 360. Angle 0 is red, 120 is green, and 240 is blue.
AngleToHue(hue)
    Converts an angle to a hue in the valid range.
RotateHue(hsv, angle)
    Takes an HSV or HSVA value and rotates the hue forward through red, green, and blue by an angle from 0 to 360.
    (Rotating red by 60° produces yellow.) The result is another HSV or HSVA color with the same saturation and value
    as the original, but a different hue.
GrayScale(rgb)
    Takes an RGB or RGBA color and converts it to grayscale. Returns an RGB or RGBA string.
ColorTone(rgb, tone)
    Similar to GrayScale(), this proc converts an RGB or RGBA color to a range of black -> tone -> white instead of
    using strict shades of gray. The tone value is an RGB color; any alpha value is ignored.
*/

/*
Get Flat Icon DEMO by DarkCampainger

This is a test for the get flat icon proc, modified approprietly for icons and their states.
Probably not a good idea to run this unless you want to see how the proc works in detail.
mob
	icon = 'old_or_unused.dmi'
	icon_state = "green"

	Login()
		// Testing image underlays
		underlays += image(icon='old_or_unused.dmi',icon_state="red")
		underlays += image(icon='old_or_unused.dmi',icon_state="red", pixel_x = 32)
		underlays += image(icon='old_or_unused.dmi',icon_state="red", pixel_x = -32)

		// Testing image overlays
		add_overlay(image(icon='old_or_unused.dmi',icon_state="green", pixel_x = 32, pixel_y = -32))
		add_overlay(image(icon='old_or_unused.dmi',icon_state="green", pixel_x = 32, pixel_y = 32))
		add_overlay(image(icon='old_or_unused.dmi',icon_state="green", pixel_x = -32, pixel_y = -32))

		// Testing icon file overlays (defaults to mob's state)
		add_overlay('_flat_demoIcons2.dmi')

		// Testing icon_state overlays (defaults to mob's icon)
		add_overlay("white")

		// Testing dynamic icon overlays
		var/icon/I = icon('old_or_unused.dmi', icon_state="aqua")
		I.Shift(NORTH,16,1)
		add_overlay(I)

		// Testing dynamic image overlays
		I=image(icon=I,pixel_x = -32, pixel_y = 32)
		add_overlay(I)

		// Testing object types (and layers)
		add_overlay(/obj/effect/overlayTest)

		loc = locate (10,10,1)
	verb
		Browse_Icon()
			set name = "1. Browse Icon"
			// Give it a name for the cache
			var/iconName = "[ckey(src.name)]_flattened.dmi"
			// Send the icon to src's local cache
			src<<browse_rsc(getFlatIcon(src), iconName)
			// Display the icon in their browser
			src<<browse("<body bgcolor='#000000'><p><img src='[iconName]'></p></body>")

		Output_Icon()
			set name = "2. Output Icon"
			to_chat(src, "Icon is: [icon2base64html(getFlatIcon(src))]")

		Label_Icon()
			set name = "3. Label Icon"
			// Give it a name for the cache
			var/iconName = "[ckey(src.name)]_flattened.dmi"
			// Copy the file to the rsc manually
			var/icon/I = fcopy_rsc(getFlatIcon(src))
			// Send the icon to src's local cache
			src<<browse_rsc(I, iconName)
			// Update the label to show it
			winset(src,"imageLabel","image='[REF(I)]'");

		Add_Overlay()
			set name = "4. Add Overlay"
			add_overlay(image(icon='old_or_unused.dmi',icon_state="yellow",pixel_x = rand(-64,32), pixel_y = rand(-64,32))

		Stress_Test()
			set name = "5. Stress Test"
			for(var/i = 0 to 1000)
				// The third parameter forces it to generate a new one, even if it's already cached
				getFlatIcon(src,0,2)
				if(prob(5))
					Add_Overlay()
			Browse_Icon()

		Cache_Test()
			set name = "6. Cache Test"
			for(var/i = 0 to 1000)
				getFlatIcon(src)
			Browse_Icon()

/obj/effect/overlayTest
	icon = 'old_or_unused.dmi'
	icon_state = "blue"
	pixel_x = -24
	pixel_y = 24
	layer = TURF_LAYER // Should appear below the rest of the overlays

world
	view = "7x7"
	maxx = 20
	maxy = 20
	maxz = 1
*/

#define TO_HEX_DIGIT(n) ascii2text((n&15) + ((n&15)<10 ? 48 : 87))


	// Multiply all alpha values by this float
/icon/proc/ChangeOpacity(opacity = 1)
	MapColors(1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,opacity, 0,0,0,0)

// Convert to grayscale
/icon/proc/GrayScale()
	MapColors(0.3,0.3,0.3, 0.59,0.59,0.59, 0.11,0.11,0.11, 0,0,0)

/icon/proc/ColorTone(tone)
	GrayScale()

	var/list/TONE = ReadRGB(tone)
	var/gray = round(TONE[1]*0.3 + TONE[2]*0.59 + TONE[3]*0.11, 1)

	var/icon/upper = (255-gray) ? new(src) : null

	if(gray)
		MapColors(255/gray,0,0, 0,255/gray,0, 0,0,255/gray, 0,0,0)
		Blend(tone, ICON_MULTIPLY)
	else SetIntensity(0)
	if(255-gray)
		upper.Blend(rgb(gray,gray,gray), ICON_SUBTRACT)
		upper.MapColors((255-TONE[1])/(255-gray),0,0,0, 0,(255-TONE[2])/(255-gray),0,0, 0,0,(255-TONE[3])/(255-gray),0, 0,0,0,0, 0,0,0,1)
		Blend(upper, ICON_ADD)

// Take the minimum color of two icons; combine transparency as if blending with ICON_ADD
/icon/proc/MinColors(icon)
	var/icon/I = new(src)
	I.Opaque()
	I.Blend(icon, ICON_SUBTRACT)
	Blend(I, ICON_SUBTRACT)

// Take the maximum color of two icons; combine opacity as if blending with ICON_OR
/icon/proc/MaxColors(icon)
	var/icon/I
	if(isicon(icon))
		I = new(icon)
	else
		// solid color
		I = new(src)
		I.Blend("#000000", ICON_OVERLAY)
		I.SwapColor("#000000", null)
		I.Blend(icon, ICON_OVERLAY)
	var/icon/J = new(src)
	J.Opaque()
	I.Blend(J, ICON_SUBTRACT)
	Blend(I, ICON_OR)

// make this icon fully opaque--transparent pixels become black
/icon/proc/Opaque(background = "#000000")
	SwapColor(null, background)
	MapColors(1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,0, 0,0,0,1)

// Change a grayscale icon into a white icon where the original color becomes the alpha
// I.e., black -> transparent, gray -> translucent white, white -> solid white
/icon/proc/BecomeAlphaMask()
	SwapColor(null, "#000000ff")	// don't let transparent become gray
	MapColors(0,0,0,0.3, 0,0,0,0.59, 0,0,0,0.11, 0,0,0,0, 1,1,1,0)

/icon/proc/UseAlphaMask(mask)
	Opaque()
	AddAlphaMask(mask)

/icon/proc/AddAlphaMask(mask)
	var/icon/M = new(mask)
	M.Blend("#ffffff", ICON_SUBTRACT)
	// apply mask
	Blend(M, ICON_ADD)

/*
	HSV format is represented as "#hhhssvv" or "#hhhssvvaa"

	Hue ranges from 0 to 0x5ff (1535)

		0x000 = red
		0x100 = yellow
		0x200 = green
		0x300 = cyan
		0x400 = blue
		0x500 = magenta

	Saturation is from 0 to 0xff (255)

		More saturation = more color
		Less saturation = more gray

	Value ranges from 0 to 0xff (255)

		Higher value means brighter color
 */

/proc/ReadRGB(rgb)
	if(!rgb)
		return

	// interpret the HSV or HSVA value
	var/i=1,start=1
	if(text2ascii(rgb) == 35) ++start // skip opening #
	var/ch,which=0,r=0,g=0,b=0,alpha=0,usealpha
	var/digits=0
	for(i=start, i<=length(rgb), ++i)
		ch = text2ascii(rgb, i)
		if(ch < 48 || (ch > 57 && ch < 65) || (ch > 70 && ch < 97) || ch > 102)
			break
		++digits
		if(digits == 8)
			break

	var/single = digits < 6
	if(digits != 3 && digits != 4 && digits != 6 && digits != 8)
		return
	if(digits == 4 || digits == 8)
		usealpha = 1
	for(i=start, digits>0, ++i)
		ch = text2ascii(rgb, i)
		if(ch >= 48 && ch <= 57)
			ch -= 48
		else if(ch >= 65 && ch <= 70)
			ch -= 55
		else if(ch >= 97 && ch <= 102)
			ch -= 87
		else
			break
		--digits
		switch(which)
			if(0)
				r = (r << 4) | ch
				if(single)
					r |= r << 4
					++which
				else if(!(digits & 1))
					++which
			if(1)
				g = (g << 4) | ch
				if(single)
					g |= g << 4
					++which
				else if(!(digits & 1))
					++which
			if(2)
				b = (b << 4) | ch
				if(single)
					b |= b << 4
					++which
				else if(!(digits & 1))
					++which
			if(3)
				alpha = (alpha << 4) | ch
				if(single)
					alpha |= alpha << 4

	. = list(r, g, b)
	if(usealpha)
		. += alpha

/proc/ReadHSV(hsv)
	if(!hsv)
		return

	// interpret the HSV or HSVA value
	var/i=1,start=1
	if(text2ascii(hsv) == 35)
		++start // skip opening #
	var/ch,which=0,hue=0,sat=0,val=0,alpha=0,usealpha
	var/digits=0
	for(i=start, i<=length(hsv), ++i)
		ch = text2ascii(hsv, i)
		if(ch < 48 || (ch > 57 && ch < 65) || (ch > 70 && ch < 97) || ch > 102)
			break
		++digits
		if(digits == 9)
			break
	if(digits > 7)
		usealpha = 1
	if(digits <= 4)
		++which
	if(digits <= 2)
		++which
	for(i=start, digits>0, ++i)
		ch = text2ascii(hsv, i)
		if(ch >= 48 && ch <= 57)
			ch -= 48
		else if(ch >= 65 && ch <= 70)
			ch -= 55
		else if(ch >= 97 && ch <= 102)
			ch -= 87
		else
			break
		--digits
		switch(which)
			if(0)
				hue = (hue << 4) | ch
				if(digits == (usealpha ? 6 : 4))
					++which
			if(1)
				sat = (sat << 4) | ch
				if(digits == (usealpha ? 4 : 2))
					++which
			if(2)
				val = (val << 4) | ch
				if(digits == (usealpha ? 2 : 0))
					++which
			if(3)
				alpha = (alpha << 4) | ch

	. = list(hue, sat, val)
	if(usealpha)
		. += alpha

/proc/HSVtoRGB(hsv)
	if(!hsv)
		return "#000000"
	var/list/HSV = ReadHSV(hsv)
	if(!HSV)
		return "#000000"

	var/hue = HSV[1]
	var/sat = HSV[2]
	var/val = HSV[3]

	// Compress hue into easier-to-manage range
	hue -= hue >> 8
	if(hue >= 0x5fa)
		hue -= 0x5fa

	var/hi,mid,lo,r,g,b
	hi = val
	lo = round((255 - sat) * val / 255, 1)
	mid = lo + round(abs(round(hue, 510) - hue) * (hi - lo) / 255, 1)
	if(hue >= 765)
		if(hue >= 1275) {r=hi;  g=lo;  b=mid}
		else if(hue >= 1020) {r=mid; g=lo;  b=hi }
		else {r=lo;  g=mid; b=hi }
	else
		if(hue >= 510) {r=lo;  g=hi;  b=mid}
		else if(hue >= 255) {r=mid; g=hi;  b=lo }
		else {r=hi;  g=mid; b=lo }

	return (HSV.len > 3) ? rgb(r,g,b,HSV[4]) : rgb(r,g,b)

/proc/RGBtoHSV(rgb)
	if(!rgb)
		return "#0000000"
	var/list/RGB = ReadRGB(rgb)
	if(!RGB)
		return "#0000000"

	var/r = RGB[1]
	var/g = RGB[2]
	var/b = RGB[3]
	var/hi = max(r,g,b)
	var/lo = min(r,g,b)

	var/val = hi
	var/sat = hi ? round((hi-lo) * 255 / hi, 1) : 0
	var/hue = 0

	if(sat)
		var/dir
		var/mid
		if(hi == r)
			if(lo == b) {hue=0; dir=1; mid=g}
			else {hue=1535; dir=-1; mid=b}
		else if(hi == g)
			if(lo == r) {hue=512; dir=1; mid=b}
			else {hue=511; dir=-1; mid=r}
		else if(hi == b)
			if(lo == g) {hue=1024; dir=1; mid=r}
			else {hue=1023; dir=-1; mid=g}
		hue += dir * round((mid-lo) * 255 / (hi-lo), 1)

	return hsv(hue, sat, val, (RGB.len>3 ? RGB[4] : null))

/proc/hsv(hue, sat, val, alpha)
	if(hue < 0 || hue >= 1536)
		hue %= 1536
	if(hue < 0)
		hue += 1536
	if((hue & 0xFF) == 0xFF)
		++hue
		if(hue >= 1536)
			hue = 0
	if(sat < 0)
		sat = 0
	if(sat > 255)
		sat = 255
	if(val < 0)
		val = 0
	if(val > 255)
		val = 255
	. = "#"
	. += TO_HEX_DIGIT(hue >> 8)
	. += TO_HEX_DIGIT(hue >> 4)
	. += TO_HEX_DIGIT(hue)
	. += TO_HEX_DIGIT(sat >> 4)
	. += TO_HEX_DIGIT(sat)
	. += TO_HEX_DIGIT(val >> 4)
	. += TO_HEX_DIGIT(val)
	if(!isnull(alpha))
		if(alpha < 0)
			alpha = 0
		if(alpha > 255)
			alpha = 255
		. += TO_HEX_DIGIT(alpha >> 4)
		. += TO_HEX_DIGIT(alpha)

/*
	Smooth blend between HSV colors

	amount=0 is the first color
	amount=1 is the second color
	amount=0.5 is directly between the two colors

	amount<0 or amount>1 are allowed
 */
/proc/BlendHSV(hsv1, hsv2, amount)
	var/list/HSV1 = ReadHSV(hsv1)
	var/list/HSV2 = ReadHSV(hsv2)

	// add missing alpha if needed
	if(HSV1.len < HSV2.len)
		HSV1 += 255
	else if(HSV2.len < HSV1.len)
		HSV2 += 255
	var/usealpha = HSV1.len > 3

	// normalize hsv values in case anything is screwy
	if(HSV1[1] > 1536)
		HSV1[1] %= 1536
	if(HSV2[1] > 1536)
		HSV2[1] %= 1536
	if(HSV1[1] < 0)
		HSV1[1] += 1536
	if(HSV2[1] < 0)
		HSV2[1] += 1536
	if(!HSV1[3]) {HSV1[1] = 0; HSV1[2] = 0}
	if(!HSV2[3]) {HSV2[1] = 0; HSV2[2] = 0}

	// no value for one color means don't change saturation
	if(!HSV1[3])
		HSV1[2] = HSV2[2]
	if(!HSV2[3])
		HSV2[2] = HSV1[2]
	// no saturation for one color means don't change hues
	if(!HSV1[2])
		HSV1[1] = HSV2[1]
	if(!HSV2[2])
		HSV2[1] = HSV1[1]

	// Compress hues into easier-to-manage range
	HSV1[1] -= HSV1[1] >> 8
	HSV2[1] -= HSV2[1] >> 8

	var/hue_diff = HSV2[1] - HSV1[1]
	if(hue_diff > 765)
		hue_diff -= 1530
	else if(hue_diff <= -765)
		hue_diff += 1530

	var/hue = round(HSV1[1] + hue_diff * amount, 1)
	var/sat = round(HSV1[2] + (HSV2[2] - HSV1[2]) * amount, 1)
	var/val = round(HSV1[3] + (HSV2[3] - HSV1[3]) * amount, 1)
	var/alpha = usealpha ? round(HSV1[4] + (HSV2[4] - HSV1[4]) * amount, 1) : null

	// normalize hue
	if(hue < 0 || hue >= 1530)
		hue %= 1530
	if(hue < 0)
		hue += 1530
	// decompress hue
	hue += round(hue / 255)

	return hsv(hue, sat, val, alpha)

/*
	Smooth blend between RGB colors

	amount=0 is the first color
	amount=1 is the second color
	amount=0.5 is directly between the two colors

	amount<0 or amount>1 are allowed
 */
/proc/BlendRGB(rgb1, rgb2, amount)
	var/list/RGB1 = ReadRGB(rgb1)
	var/list/RGB2 = ReadRGB(rgb2)

	// add missing alpha if needed
	if(RGB1.len < RGB2.len)
		RGB1 += 255
	else if(RGB2.len < RGB1.len)
		RGB2 += 255
	var/usealpha = RGB1.len > 3

	var/r = round(RGB1[1] + (RGB2[1] - RGB1[1]) * amount, 1)
	var/g = round(RGB1[2] + (RGB2[2] - RGB1[2]) * amount, 1)
	var/b = round(RGB1[3] + (RGB2[3] - RGB1[3]) * amount, 1)
	var/alpha = usealpha ? round(RGB1[4] + (RGB2[4] - RGB1[4]) * amount, 1) : null

	return isnull(alpha) ? rgb(r, g, b) : rgb(r, g, b, alpha)

/proc/BlendRGBasHSV(rgb1, rgb2, amount)
	return HSVtoRGB(RGBtoHSV(rgb1), RGBtoHSV(rgb2), amount)

/proc/HueToAngle(hue)
	// normalize hsv in case anything is screwy
	if(hue < 0 || hue >= 1536)
		hue %= 1536
	if(hue < 0)
		hue += 1536
	// Compress hue into easier-to-manage range
	hue -= hue >> 8
	return hue / (1530/360)

/proc/AngleToHue(angle)
	// normalize hsv in case anything is screwy
	if(angle < 0 || angle >= 360)
		angle -= 360 * round(angle / 360)
	var/hue = angle * (1530/360)
	// Decompress hue
	hue += round(hue / 255)
	return hue


// positive angle rotates forward through red->green->blue
/proc/RotateHue(hsv, angle)
	var/list/HSV = ReadHSV(hsv)

	// normalize hsv in case anything is screwy
	if(HSV[1] >= 1536)
		HSV[1] %= 1536
	if(HSV[1] < 0)
		HSV[1] += 1536

	// Compress hue into easier-to-manage range
	HSV[1] -= HSV[1] >> 8

	if(angle < 0 || angle >= 360)
		angle -= 360 * round(angle / 360)
	HSV[1] = round(HSV[1] + angle * (1530/360), 1)

	// normalize hue
	if(HSV[1] < 0 || HSV[1] >= 1530)
		HSV[1] %= 1530
	if(HSV[1] < 0)
		HSV[1] += 1530
	// decompress hue
	HSV[1] += round(HSV[1] / 255)

	return hsv(HSV[1], HSV[2], HSV[3], (HSV.len > 3 ? HSV[4] : null))

// Convert an rgb color to grayscale
/proc/GrayScale(rgb)
	var/list/RGB = ReadRGB(rgb)
	var/gray = RGB[1]*0.3 + RGB[2]*0.59 + RGB[3]*0.11
	return (RGB.len > 3) ? rgb(gray, gray, gray, RGB[4]) : rgb(gray, gray, gray)

// Change grayscale color to black->tone->white range
/proc/ColorTone(rgb, tone)
	var/list/RGB = ReadRGB(rgb)
	var/list/TONE = ReadRGB(tone)

	var/gray = RGB[1]*0.3 + RGB[2]*0.59 + RGB[3]*0.11
	var/tone_gray = TONE[1]*0.3 + TONE[2]*0.59 + TONE[3]*0.11

	if(gray <= tone_gray)
		return BlendRGB("#000000", tone, gray/(tone_gray || 1))
	else
		return BlendRGB(tone, "#ffffff", (gray-tone_gray)/((255-tone_gray) || 1))


//Used in the OLD chem colour mixing algorithm
/proc/GetColors(hex)
	hex = uppertext(hex)
	// No alpha set? Default to full alpha.
	if(length(hex) == 7)
		hex += "FF"
	var/hi1 = text2ascii(hex, 2) // R
	var/lo1 = text2ascii(hex, 3) // R
	var/hi2 = text2ascii(hex, 4) // G
	var/lo2 = text2ascii(hex, 5) // G
	var/hi3 = text2ascii(hex, 6) // B
	var/lo3 = text2ascii(hex, 7) // B
	var/hi4 = text2ascii(hex, 8) // A
	var/lo4 = text2ascii(hex, 9) // A
	return list(((hi1>= 65 ? hi1-55 : hi1-48)<<4) | (lo1 >= 65 ? lo1-55 : lo1-48),
		((hi2 >= 65 ? hi2-55 : hi2-48)<<4) | (lo2 >= 65 ? lo2-55 : lo2-48),
		((hi3 >= 65 ? hi3-55 : hi3-48)<<4) | (lo3 >= 65 ? lo3-55 : lo3-48),
		((hi4 >= 65 ? hi4-55 : hi4-48)<<4) | (lo4 >= 65 ? lo4-55 : lo4-48))

/// Create a single [/icon] from a given [/atom] or [/image].
///
/// Very low-performance. Should usually only be used for HTML, where BYOND's
/// appearance system (overlays/underlays, etc.) is not available.
///
/// Only the first argument is required.
/proc/getFlatIcon(image/appearance, defdir, deficon, defstate, defblend, start = TRUE, no_anim = FALSE)
	// Loop through the underlays, then overlays, sorting them into the layers list
	#define PROCESS_OVERLAYS_OR_UNDERLAYS(flat, process, base_layer) \
		for (var/i in 1 to process.len) { \
			var/image/current = process[i]; \
			if (!current) { \
				continue; \
			} \
			if (current.plane != FLOAT_PLANE && current.plane != appearance.plane) { \
				continue; \
			} \
			var/current_layer = current.layer; \
			if (current_layer < 0) { \
				if (current_layer <= -1000) { \
					return flat; \
				} \
				current_layer = base_layer + appearance.layer + current_layer / 1000; \
			} \
			/* If we are using topdown rendering, chop that part off so things layer together as expected */ \
			if((current_layer >= TOPDOWN_LAYER && current_layer < EFFECTS_LAYER) || current_layer > TOPDOWN_LAYER + EFFECTS_LAYER) { \
				current_layer -= TOPDOWN_LAYER; \
			} \
			for (var/index_to_compare_to in 1 to layers.len) { \
				var/compare_to = layers[index_to_compare_to]; \
				if (current_layer < layers[compare_to]) { \
					layers.Insert(index_to_compare_to, current); \
					break; \
				} \
			} \
			layers[current] = current_layer; \
		}

	var/static/icon/flat_template = icon('icons/blanks/32x32.dmi', "nothing")
	var/icon/flat = icon(flat_template)

	if(!appearance || appearance.alpha <= 0)
		return flat

	if(start)
		if(!defdir)
			defdir = appearance.dir
		if(!deficon)
			deficon = appearance.icon
		if(!defstate)
			defstate = appearance.icon_state
		if(!defblend)
			defblend = appearance.blend_mode

	var/curicon = appearance.icon || deficon
	var/curstate = appearance.icon_state || defstate
	var/curdir = (!appearance.dir || appearance.dir == SOUTH) ? defdir : appearance.dir

	var/render_icon = curicon

	if (render_icon)
		var/curstates = icon_states(curicon)
		if(!(curstate in curstates))
			if ("" in curstates)
				curstate = ""
			else
				render_icon = FALSE

	var/base_icon_dir //We'll use this to get the icon state to display if not null BUT NOT pass it to overlays as the dir we have

	if(render_icon)
		//Try to remove/optimize this section if you can, it's a CPU hog.
		//Determines if there're directionals.
		if (curdir != SOUTH)
			// icon states either have 1, 4 or 8 dirs. We only have to check
			// one of NORTH, EAST or WEST to know that this isn't a 1-dir icon_state since they just have SOUTH.
			if(!length(icon_states(icon(curicon, curstate, NORTH))))
				base_icon_dir = SOUTH

		var/list/icon_dimensions = get_icon_dimensions(curicon)
		var/icon_width = icon_dimensions["width"]
		var/icon_height = icon_dimensions["height"]
		if(icon_width != 32 || icon_height != 32)
			flat.Scale(icon_width, icon_height)

	if(!base_icon_dir)
		base_icon_dir = curdir

	var/curblend = appearance.blend_mode || defblend

	if(appearance.overlays.len || appearance.underlays.len)
		// Layers will be a sorted list of icons/overlays, based on the order in which they are displayed
		var/list/layers = list()
		var/image/copy
		// Add the atom's icon itself, without pixel_x/y offsets.
		if(render_icon)
			copy = image(icon=curicon, icon_state=curstate, layer=appearance.layer, dir=base_icon_dir)
			copy.color = appearance.color
			copy.alpha = appearance.alpha
			copy.blend_mode = curblend
			layers[copy] = appearance.layer

		PROCESS_OVERLAYS_OR_UNDERLAYS(flat, appearance.underlays, 0)
		PROCESS_OVERLAYS_OR_UNDERLAYS(flat, appearance.overlays, 1)

		var/icon/add // Icon of overlay being added

		var/flatX1 = 1
		var/flatX2 = flat.Width()
		var/flatY1 = 1
		var/flatY2 = flat.Height()

		var/addX1 = 0
		var/addX2 = 0
		var/addY1 = 0
		var/addY2 = 0

		for(var/image/layer_image as anything in layers)
			if(layer_image.alpha == 0)
				continue

			if(layer_image == copy) // 'layer_image' is an /image based on the object being flattened.
				curblend = BLEND_OVERLAY
				add = icon(layer_image.icon, layer_image.icon_state, base_icon_dir)
			else // 'I' is an appearance object.
				add = getFlatIcon(image(layer_image), curdir, curicon, curstate, curblend, FALSE, no_anim)
			if(!add)
				continue

			// Find the new dimensions of the flat icon to fit the added overlay
			addX1 = min(flatX1, layer_image.pixel_x + 1)
			addX2 = max(flatX2, layer_image.pixel_x + add.Width())
			addY1 = min(flatY1, layer_image.pixel_y + 1)
			addY2 = max(flatY2, layer_image.pixel_y + add.Height())

			if (
				addX1 != flatX1 \
				|| addX2 != flatX2 \
				|| addY1 != flatY1 \
				|| addY2 != flatY2 \
			)
				// Resize the flattened icon so the new icon fits
				flat.Crop(
					addX1 - flatX1 + 1,
					addY1 - flatY1 + 1,
					addX2 - flatX1 + 1,
					addY2 - flatY1 + 1
				)

				flatX1 = addX1
				flatX2 = addX2
				flatY1 = addY1
				flatY2 = addY2

			// Blend the overlay into the flattened icon
			flat.Blend(add, blendMode2iconMode(curblend), layer_image.pixel_x + 2 - flatX1, layer_image.pixel_y + 2 - flatY1)

		if(appearance.color)
			if(islist(appearance.color))
				flat.MapColors(arglist(appearance.color))
			else
				flat.Blend(appearance.color, ICON_MULTIPLY)

		if(appearance.alpha < 255)
			flat.Blend(rgb(255, 255, 255, appearance.alpha), ICON_MULTIPLY)

		if(no_anim)
			//Clean up repeated frames
			var/icon/cleaned = new /icon()
			cleaned.Insert(flat, "", SOUTH, 1, 0)
			return cleaned
		else
			return icon(flat, "", SOUTH)
	else if (render_icon) // There's no overlays.
		var/icon/final_icon = icon(icon(curicon, curstate, base_icon_dir), "", SOUTH, no_anim ? TRUE : null)

		if (appearance.alpha < 255)
			final_icon.Blend(rgb(255,255,255, appearance.alpha), ICON_MULTIPLY)

		if (appearance.color)
			if (islist(appearance.color))
				final_icon.MapColors(arglist(appearance.color))
			else
				final_icon.Blend(appearance.color, ICON_MULTIPLY)

		return final_icon

	#undef PROCESS_OVERLAYS_OR_UNDERLAYS

/proc/getIconMask(atom/A)//By yours truly. Creates a dynamic mask for a mob/whatever. /N
	var/icon/alpha_mask = new(A.icon,A.icon_state)//So we want the default icon and icon state of A.
	for(var/V in A.overlays)//For every image in overlays. var/image/I will not work, don't try it.
		var/image/I = V
		if(I.layer>A.layer)
			continue//If layer is greater than what we need, skip it.
		var/icon/image_overlay = new(I.icon,I.icon_state)//Blend only works with icon objects.
		//Also, icons cannot directly set icon_state. Slower than changing variables but whatever.
		alpha_mask.Blend(image_overlay,ICON_OR)//OR so they are lumped together in a nice overlay.
	return alpha_mask//And now return the mask.

/mob/proc/AddCamoOverlay(atom/A)//A is the atom which we are using as the overlay.
	var/icon/opacity_icon = new(A.icon, A.icon_state)//Don't really care for overlays/underlays.
	//Now we need to culculate overlays+underlays and add them together to form an image for a mask.
	var/icon/alpha_mask = getIconMask(src)//getFlatIcon(src) is accurate but SLOW. Not designed for running each tick. This is also a little slow since it's blending a bunch of icons together but good enough.
	opacity_icon.AddAlphaMask(alpha_mask)//Likely the main source of lag for this proc. Probably not designed to run each tick.
	opacity_icon.ChangeOpacity(0.4)//Front end for MapColors so it's fast. 0.5 means half opacity and looks the best in my opinion.
	for(var/i=0,i<5,i++)//And now we add it as overlays. It's faster than creating an icon and then merging it.
		var/image/I = image("icon" = opacity_icon, "icon_state" = A.icon_state, "layer" = layer+0.8)//So it's above other stuff but below weapons and the like.
		switch(i)//Now to determine offset so the result is somewhat blurred.
			if(1)
				I.pixel_x--
			if(2)
				I.pixel_x++
			if(3)
				I.pixel_y--
			if(4)
				I.pixel_y++
		add_overlay(I)//And finally add the overlay.

/proc/getHologramIcon(icon/A, safety=1)//If safety is on, a new icon is not created.
	var/icon/flat_icon = safety ? A : new(A)//Has to be a new icon to not constantly change the same icon.
	flat_icon.ColorTone(rgb(125,180,225))//Let's make it bluish.
	flat_icon.ChangeOpacity(0.5)//Make it half transparent.
	var/icon/alpha_mask = new('icons/effects/effects.dmi', "scanline")//Scanline effect.
	flat_icon.AddAlphaMask(alpha_mask)//Finally, let's mix in a distortion effect.
	return flat_icon

//What the mob looks like as animated static
//By vg's ComicIronic
/proc/getStaticIcon(icon/A, safety = TRUE)
	var/icon/flat_icon = safety ? A : new(A)
	flat_icon.Blend(rgb(255,255,255))
	flat_icon.BecomeAlphaMask()
	var/icon/static_icon = icon('icons/effects/effects.dmi', "static_base")
	static_icon.AddAlphaMask(flat_icon)
	return static_icon

//What the mob looks like as a pitch black outline
//By vg's ComicIronic
/proc/getBlankIcon(icon/A, safety=1)
	var/icon/flat_icon = safety ? A : new(A)
	flat_icon.Blend(rgb(255,255,255))
	flat_icon.BecomeAlphaMask()
	var/icon/blank_icon = new/icon('icons/effects/effects.dmi', "blank_base")
	blank_icon.AddAlphaMask(flat_icon)
	return blank_icon


//Dwarf fortress style icons based on letters (defaults to the first letter of the Atom's name)
//By vg's ComicIronic
/proc/getLetterImage(atom/A, letter= "", uppercase = 0)
	if(!A)
		return

	var/icon/atom_icon = new(A.icon, A.icon_state)

	if(!letter)
		letter = copytext(A.name, 1, 2)
		if(uppercase == 1)
			letter = uppertext(letter)
		else if(uppercase == -1)
			letter = lowertext(letter)

	var/image/text_image = new(loc = A)
	text_image.maptext = "<font size = 4>[letter]</font>"
	text_image.pixel_x = 7
	text_image.pixel_y = 5
	qdel(atom_icon)
	return text_image

GLOBAL_LIST_EMPTY(friendly_animal_types)

// Pick a random animal instead of the icon, and use that instead
/proc/getRandomAnimalImage(atom/A)
	if(!GLOB.friendly_animal_types.len)
		for(var/T in typesof(/mob/living/simple_animal))
			var/mob/living/simple_animal/SA = T
			if(initial(SA.gold_core_spawnable) == FRIENDLY_SPAWN)
				GLOB.friendly_animal_types += SA


	var/mob/living/simple_animal/SA = pick(GLOB.friendly_animal_types)

	var/icon = initial(SA.icon)
	var/icon_state = initial(SA.icon_state)

	var/image/final_image = image(icon, icon_state=icon_state, loc = A)

	if(ispath(SA, /mob/living/simple_animal/butterfly))
		final_image.color = rgb(rand(0,255), rand(0,255), rand(0,255))

	// For debugging
	final_image.text = initial(SA.name)
	return final_image

//Interface for using DrawBox() to draw 1 pixel on a coordinate.
//Returns the same icon specifed in the argument, but with the pixel drawn
/proc/DrawPixel(icon/I,colour,drawX,drawY)
	if(!I)
		return 0

	var/Iwidth = I.Width()
	var/Iheight = I.Height()

	if(drawX > Iwidth || drawX <= 0)
		return 0
	if(drawY > Iheight || drawY <= 0)
		return 0

	I.DrawBox(colour,drawX, drawY)
	return I


//Interface for easy drawing of one pixel on an atom.
/atom/proc/DrawPixelOn(colour, drawX, drawY)
	var/icon/I = new(icon)
	var/icon/J = DrawPixel(I, colour, drawX, drawY)
	if(J) //Only set the icon if it succeeded, the icon without the pixel is 1000x better than a black square.
		icon = J
		return J
	return 0

//For creating consistent icons for human looking simple animals
/proc/get_flat_human_icon(icon_id, datum/job/J, datum/preferences/prefs, dummy_key, showDirs = GLOB.cardinals, outfit_override = null, mob/living/carbon/human/human_gear_override, copy_appearance = FALSE)
	var/static/list/humanoid_icon_cache = list()
	if(!icon_id || !humanoid_icon_cache[icon_id])
		var/mob/living/carbon/human/dummy/body = generate_or_wait_for_human_dummy(dummy_key)

		if(prefs)
			prefs.copy_to(body,TRUE,FALSE)
		if(human_gear_override) //EVIL CODE!!
			var/static/list/all_item_slots = ALL_ITEM_SLOTS
			for(var/slot in all_item_slots)
				var/obj/item/item = human_gear_override.get_item_by_slot(slot)
				if(!item)
					continue
				var/obj/item/new_item
				if(item.visual_replacement)
					new_item = new item.visual_replacement(body)
				else
					new_item = new item.type(body)
				new_item.icon_state = item.icon_state
				new_item.flags_inv = item.flags_inv
				new_item.body_parts_covered = item.body_parts_covered
				new_item.color = item.color
				body.equip_to_slot_if_possible(new_item, slot, bypass_equip_delay_self = TRUE)

			if(copy_appearance)
				human_gear_override.dna.transfer_identity(body)
				body.updateappearance(icon_update=1, mutcolor_update=1)
		else if(J)
			J.equip(body, TRUE, FALSE, outfit_override = outfit_override)
		else if (outfit_override)
			body.equipOutfit(outfit_override,visualsOnly = TRUE)

		body.update_inv_hands(hide_experimental = TRUE)
		body.update_inv_belt(hide_experimental = TRUE)
		body.update_inv_back(hide_experimental = TRUE)
		body.update_inv_head(hide_nonstandard = TRUE)

		var/icon/out_icon = icon('icons/effects/effects.dmi', "nothing")
		for(var/D in showDirs)
			body.setDir(D)
			var/icon/partial = getFlatIcon(body)
			out_icon.Insert(partial,dir=D)

		body.update_inv_hands()
		body.update_inv_belt()
		body.update_inv_back()
		body.update_inv_head()

		humanoid_icon_cache[icon_id] = out_icon
		dummy_key? unset_busy_human_dummy(dummy_key) : qdel(body)
		return out_icon
	else
		return humanoid_icon_cache[icon_id]

/**
 * A simpler version of get_flat_human_icon() that uses an existing human as a base to create the icon.
 * Does not feature caching yet, since I could not think of a good way to cache them without having a possibility
 * of using the cached version when we don't want to, so only use this proc if you just need this flat icon
 * generated once and handle the caching yourself if you need to access that icon multiple times, or
 * refactor this proc to feature caching of icons.
 *
 * Arguments:
 * * existing_human - The human we want to get a flat icon out of.
 * * directions_to_output - The directions of the resulting flat icon, defaults to all cardinal directions.
 */
/proc/get_flat_existing_human_icon(mob/living/carbon/human/existing_human, directions_to_output = GLOB.cardinals)
	RETURN_TYPE(/icon)
	if(!existing_human || !istype(existing_human))
		CRASH("Attempted to call get_flat_existing_human_icon on a [existing_human ? existing_human.type : "null"].")

	// We need to force the dir of the human so we can take those pictures, we'll set it back afterwards.
	var/initial_human_dir = existing_human.dir
	existing_human.dir = SOUTH
	var/icon/out_icon = icon('icons/effects/effects.dmi', "nothing")
	for(var/direction in directions_to_output)
		var/icon/partial = getFlatIcon(existing_human, defdir = direction)
		out_icon.Insert(partial, dir = direction)

	existing_human.dir = initial_human_dir

	return out_icon

//Hook, override to run code on- wait this is images
//Images have dir without being an atom, so they get their own definition.
//Lame.
/image/proc/setDir(newdir)
	dir = newdir

GLOBAL_LIST_INIT(freon_color_matrix, list("#2E5E69", "#60A2A8", "#A1AFB1", rgb(0,0,0)))

/obj/proc/make_frozen_visual()
	// Used to make the frozen item visuals for Freon.
	if(resistance_flags & FREEZE_PROOF)
		return
	if(!(obj_flags & FROZEN))
		name = "frozen [name]"
		add_atom_colour(GLOB.freon_color_matrix, TEMPORARY_COLOUR_PRIORITY)
		alpha -= 25
		obj_flags |= FROZEN

//Assumes already frozed
/obj/proc/make_unfrozen()
	if(obj_flags & FROZEN)
		name = replacetext(name, "frozen ", "")
		remove_atom_colour(TEMPORARY_COLOUR_PRIORITY, GLOB.freon_color_matrix)
		alpha += 25
		obj_flags &= ~FROZEN


/// generates a filename for a given asset.
/// like generate_asset_name(), except returns the rsc reference and the rsc file hash as well as the asset name (sans extension)
/// used so that certain asset files don't have to be hashed twice
/proc/generate_and_hash_rsc_file(file, dmi_file_path)
	var/rsc_ref = fcopy_rsc(file)
	var/hash
	//if we have a valid dmi file path we can trust md5'ing the rsc file because we know it doesn't have the bug described in http://www.byond.com/forum/post/2611357
	if(dmi_file_path)
		hash = md5(rsc_ref)
	else //otherwise, we need to do the expensive fcopy() workaround
		hash = md5asfile(rsc_ref)

	return list(rsc_ref, hash, "asset.[hash]")

/// Generate a filename for this asset
/// The same asset will always lead to the same asset name
/// (Generated names do not include file extention.)
/proc/generate_asset_name(file)
	return "asset.[md5(fcopy_rsc(file))]"

/// Gets a dummy savefile for usage in icon generation.
/// Savefiles generated from this proc will be empty.
/proc/get_dummy_savefile(from_failure = FALSE)
	var/static/next_id = 0
	if(next_id++ > 9)
		next_id = 0
	var/savefile_path = "tmp/dummy-save-[next_id].sav"
	try
		if(fexists(savefile_path))
			fdel(savefile_path)
		return new /savefile(savefile_path)
	catch(var/exception/error)
		// if we failed to create a dummy once, try again; maybe someone slept somewhere they shouldn't have
		if(from_failure) // this *is* the retry, something fucked up
			CRASH("get_dummy_savefile failed to create a dummy savefile: '[error]'")
		return get_dummy_savefile(from_failure = TRUE)

/**
 * Converts an icon to base64. Operates by putting the icon in the iconCache savefile,
 * exporting it as text, and then parsing the base64 from that.
 * (This relies on byond automatically storing icons in savefiles as base64)
 */
/proc/icon2base64(icon/icon)
	if (!isicon(icon))
		return FALSE
	var/savefile/dummySave = get_dummy_savefile()
	WRITE_FILE(dummySave["dummy"], icon)
	var/iconData = dummySave.ExportText("dummy")
	var/list/partial = splittext(iconData, "{")
	return replacetext(copytext_char(partial[2], 3, -5), "\n", "") //if cleanup fails we want to still return the correct base64

///given a text string, returns whether it is a valid dmi icons folder path
/proc/is_valid_dmi_file(icon_path)
	if(!istext(icon_path) || !length(icon_path))
		return FALSE

	var/is_in_icon_folder = findtextEx(icon_path, "icons/")
	var/is_dmi_file = findtextEx(icon_path, ".dmi")

	if(is_in_icon_folder && is_dmi_file)
		return TRUE
	return FALSE

/// given an icon object, dmi file path, or atom/image/mutable_appearance, attempts to find and return an associated dmi file path.
/// a weird quirk about dm is that /icon objects represent both compile-time or dynamic icons in the rsc,
/// but stringifying rsc references returns a dmi file path
/// ONLY if that icon represents a completely unchanged dmi file from when the game was compiled.
/// so if the given object is associated with an icon that was in the rsc when the game was compiled, this returns a path. otherwise it returns ""
/proc/get_icon_dmi_path(icon/icon)
	/// the dmi file path we attempt to return if the given object argument is associated with a stringifiable icon
	/// if successful, this looks like "icons/path/to/dmi_file.dmi"
	var/icon_path = ""

	if(isatom(icon) || istype(icon, /image) || istype(icon, /mutable_appearance))
		var/atom/atom_icon = icon
		icon = atom_icon.icon
		//atom icons compiled in from 'icons/path/to/dmi_file.dmi' are weird and not really icon objects that you generate with icon().
		//if they're unchanged dmi's then they're stringifiable to "icons/path/to/dmi_file.dmi"

	if(isicon(icon) && isfile(icon))
		//icons compiled in from 'icons/path/to/dmi_file.dmi' at compile time are weird and aren't really /icon objects,
		///but they pass both isicon() and isfile() checks. they're the easiest case since stringifying them gives us the path we want
		var/icon_ref = text_ref(icon)
		var/locate_icon_string = "[locate(icon_ref)]"

		icon_path = locate_icon_string

	else if(isicon(icon) && "[icon]" == "/icon")
		// icon objects generated from icon() at runtime are icons, but they AREN'T files themselves, they represent icon files.
		// if the files they represent are compile time dmi files in the rsc, then
		// the rsc reference returned by fcopy_rsc() will be stringifiable to "icons/path/to/dmi_file.dmi"
		var/rsc_ref = fcopy_rsc(icon)

		var/icon_ref = text_ref(rsc_ref)

		var/icon_path_string = "[locate(icon_ref)]"

		icon_path = icon_path_string

	else if(istext(icon))
		var/rsc_ref = fcopy_rsc(icon)
		//if its the text path of an existing dmi file, the rsc reference returned by fcopy_rsc() will be stringifiable to a dmi path

		var/rsc_ref_ref = text_ref(rsc_ref)
		var/rsc_ref_string = "[locate(rsc_ref_ref)]"

		icon_path = rsc_ref_string

	if(is_valid_dmi_file(icon_path))
		return icon_path

	return FALSE

/**
 * generate an asset for the given icon or the icon of the given appearance for [thing], and send it to any clients in target.
 * Arguments:
 * * thing - either a /icon object, or an object that has an appearance (atom, image, mutable_appearance).
 * * target - either a reference to or a list of references to /client's or mobs with clients
 * * icon_state - string to force a particular icon_state for the icon to be used
 * * dir - dir number to force a particular direction for the icon to be used
 * * frame - what frame of the icon_state's animation for the icon being used
 * * moving - whether or not to use a moving state for the given icon
 * * sourceonly - if TRUE, only generate the asset and send back the asset url, instead of tags that display the icon to players
 * * extra_clases - string of extra css classes to use when returning the icon string
 */
/proc/icon2html(atom/thing, client/target, icon_state, dir = SOUTH, frame = 1, moving = FALSE, sourceonly = FALSE, extra_classes = null)
	if (!thing)
		return
	// if(SSlag_switch.measures[DISABLE_USR_ICON2HTML] && usr && !HAS_TRAIT(usr, TRAIT_BYPASS_MEASURES))
	// 	return

	var/key
	var/icon/icon2collapse = thing

	if (!target)
		return
	if (target == world)
		target = GLOB.clients

	var/list/targets
	if (!islist(target))
		targets = list(target)
	else
		targets = target
	if(!length(targets))
		return

	//check if the given object is associated with a dmi file in the icons folder. if it is then we don't need to do a lot of work
	//for asset generation to get around byond limitations
	var/icon_path = get_icon_dmi_path(thing)

	if (!isicon(icon2collapse))
		if (isfile(thing)) //special snowflake
			var/name = SANITIZE_FILENAME("[generate_asset_name(thing)].png")
			if (!SSassets.cache[name])
				SSassets.transport.register_asset(name, thing)
			for (var/thing2 in targets)
				SSassets.transport.send_assets(thing2, name)
			if(sourceonly)
				return SSassets.transport.get_asset_url(name)
			return "<img class='[extra_classes] icon icon-misc' src='[SSassets.transport.get_asset_url(name)]'>"

		//its either an atom, image, or mutable_appearance, we want its icon var
		icon2collapse = thing.icon

		if (isnull(icon_state))
			icon_state = thing.icon_state
			//Despite casting to atom, this code path supports mutable appearances, so let's be nice to them
			if(isnull(icon_state))
				icon_state = thing::icon_state
				if (isnull(dir))
					dir = thing::dir

		if (isnull(dir))
			dir = thing.dir

		if (ishuman(thing)) // Shitty workaround for a BYOND issue.
			var/icon/temp = icon2collapse
			icon2collapse = icon()
			icon2collapse.Insert(temp, dir = SOUTH)
			dir = SOUTH
	else
		if (isnull(dir))
			dir = SOUTH
		if (isnull(icon_state))
			icon_state = ""

	icon2collapse = icon(icon2collapse, icon_state, dir, frame, moving)

	var/list/name_and_ref = generate_and_hash_rsc_file(icon2collapse, icon_path)//pretend that tuples exist

	var/rsc_ref = name_and_ref[1] //weird object that's not even readable to the debugger, represents a reference to the icons rsc entry
	var/file_hash = name_and_ref[2]
	key = "[name_and_ref[3]].png"

	if(!SSassets.cache[key])
		SSassets.transport.register_asset(key, rsc_ref, file_hash, icon_path)
	for (var/client_target in targets)
		SSassets.transport.send_assets(client_target, key)
	if(sourceonly)
		return SSassets.transport.get_asset_url(key)
	return "<img class='[extra_classes] icon icon-[icon_state]' src='[SSassets.transport.get_asset_url(key)]'>"

/proc/icon2base64html(target)
	if (!target)
		return
	var/static/list/bicon_cache = list()
	if (isicon(target))
		var/icon/target_icon = target
		var/icon_base64 = icon2base64(target_icon)

		if (target_icon.Height() > 32 || target_icon.Width() > 32)
			var/icon_md5 = md5(icon_base64)
			icon_base64 = bicon_cache[icon_md5]
			if (!icon_base64) // Doesn't exist yet, make it.
				bicon_cache[icon_md5] = icon_base64 = icon2base64(target_icon)


		return "<img class='icon icon-misc' src='data:image/png;base64,[icon_base64]'>"

	// Either an atom or somebody fucked up and is gonna get a runtime, which I'm fine with.
	var/atom/target_atom = target
	var/key = "[istype(target_atom.icon, /icon) ? "[REF(target_atom.icon)]" : target_atom.icon]:[target_atom.icon_state]"


	if (!bicon_cache[key]) // Doesn't exist, make it.
		var/icon/target_icon = icon(target_atom.icon, target_atom.icon_state, SOUTH, 1)
		if (ishuman(target)) // Shitty workaround for a BYOND issue.
			var/icon/temp = target_icon
			target_icon = icon()
			target_icon.Insert(temp, dir = SOUTH)

		bicon_cache[key] = icon2base64(target_icon)

	return "<img class='icon icon-[target_atom.icon_state]' src='data:image/png;base64,[bicon_cache[key]]'>"

//Costlier version of icon2html() that uses getFlatIcon() to account for overlays, underlays, etc. Use with extreme moderation, ESPECIALLY on mobs.
/proc/costly_icon2html(thing, target, sourceonly = FALSE)
	if (!thing)
		return
	// if(SSlag_switch.measures[DISABLE_USR_ICON2HTML] && usr && !HAS_TRAIT(usr, TRAIT_BYPASS_MEASURES))
	// 	return

	if (isicon(thing))
		return icon2html(thing, target)

	var/icon/flat_icon = getFlatIcon(thing)
	return icon2html(flat_icon, target, sourceonly = sourceonly)

/proc/RGBMatrixTransform(list/color, list/cm)
	ASSERT(cm.len >= 9)
	if(cm.len < 12)		// fill in the rest
		for(var/i in 1 to (12 - cm.len))
			cm += 0
	if(!islist(color))
		color = ReadRGB(color)
	color[1] = color[1] * cm[1] + color[2] * cm[2] + color[3] * cm[3] + cm[10] * 255
	color[2] = color[1] * cm[4] + color[2] * cm[5] + color[3] * cm[6] + cm[11] * 255
	color[3] = color[1] * cm[7] + color[2] * cm[8] + color[3] * cm[9] + cm[12] * 255
	return rgb(color[1], color[2], color[3])

/// Returns a list containing the width and height of an icon file
/proc/get_icon_dimensions(icon_path)
	// Icons can be a real file(), a rsc backed file(), a dynamic rsc (dyn.rsc) reference (known as a cache reference in byond docs), or an /icon which is pointing to one of those.
	// Runtime generated dynamic icons are an unbounded concept cache identity wise, the same icon can exist millions of ways and holding them in a list as a key can lead to unbounded memory usage if called often by consumers.
	// Check distinctly that this is something that has this unspecified concept, and thus that we should not cache.
	if (!isfile(icon_path) || !length("[icon_path]"))
		var/icon/my_icon = icon(icon_path)
		return list("width" = my_icon.Width(), "height" = my_icon.Height())
	if (isnull(GLOB.icon_dimensions[icon_path]))
		var/icon/my_icon = icon(icon_path)
		GLOB.icon_dimensions[icon_path] = list("width" = my_icon.Width(), "height" = my_icon.Height())
	return GLOB.icon_dimensions[icon_path]

/proc/ma2html(mutable_appearance/appearance, mob/viewer, extra_classes = "")
	if(isatom(appearance))
		var/atom/atom = appearance
		appearance = copy_appearance_filter_overlays(atom.appearance)
	else if(isappearance_or_image(appearance) || isicon(appearance))
		appearance = copy_appearance_filter_overlays(appearance)
	else
		CRASH("Invalid appearance passed to ma2html - either a appearance, image, icon, or atom must be passed!")

	if(istype(viewer, /client))
		var/client/client_user = viewer
		viewer = client_user.mob
	if(!ismob(viewer))
		CRASH("Invalid viewer passed to ma2html")
	var/atom/movable/screen/container = viewer.send_appearance(appearance)
	if(QDELETED(container))
		CRASH("Failed to send appearance to client")
	return "<img class='icon [extra_classes]' src='\ref[container]' style='image-rendering: pixelated; -ms-interpolation-mode: nearest-neighbor'>"

/**
 * Copies the passed /appearance, returns a /mutable_appearance
 *
 * Filters out certain overlays from the copy, depending on their planes
 * Prevents stuff like lighting from being copied to the new appearance
 */
/proc/copy_appearance_filter_overlays(appearance_to_copy) as /mutable_appearance
	RETURN_TYPE(/mutable_appearance)
	var/mutable_appearance/copy = new(appearance_to_copy)
	var/static/list/plane_whitelist = list(FLOAT_PLANE, GAME_PLANE, FLOOR_PLANE)

	copy.overlays = recursively_filter_emissive_blockers(copy.overlays, plane_whitelist)
	copy.underlays = recursively_filter_emissive_blockers(copy.underlays, plane_whitelist)

	return copy

/proc/recursively_filter_emissive_blockers(list/input_list, list/plane_whitelist)
	var/list/filtered_list = list()

	for(var/mutable_appearance/overlay_item as anything in input_list)
		if(isnull(overlay_item))
			continue

		var/mutable_appearance/real = new()
		real.appearance = overlay_item

		// Skip emissive blockers
		if(is_emissive_blocker(real))
			continue

		// Skip non-whitelisted planes
		if(!(real.plane in plane_whitelist))
			continue

		if(length(real.overlays))
			real.overlays = recursively_filter_emissive_blockers(real.overlays, plane_whitelist)
		if(length(real.underlays))
			real.underlays = recursively_filter_emissive_blockers(real.underlays, plane_whitelist)

		filtered_list += real

	return filtered_list

/proc/is_emissive_blocker(mutable_appearance/MA)
	if(MA.plane == EMISSIVE_PLANE)
		return TRUE
	return FALSE

/// Makes a client temporarily aware of an appearance via and invisible vis contents object.
/mob/proc/send_appearance(mutable_appearance/appearance) as /atom/movable/screen
	RETURN_TYPE(/atom/movable/screen)
	if(!hud_used || isnull(appearance))
		return

	var/atom/movable/screen/container = new
	container.appearance = appearance

	hud_used.vis_holder.vis_contents += container
	addtimer(CALLBACK(src, PROC_REF(remove_appearance), container), 5 SECONDS)

	return container

/mob/proc/remove_appearance(atom/movable/container)
	if(!hud_used)
		return

	hud_used.vis_holder.vis_contents -= container

GLOBAL_LIST_EMPTY(headshot_cache)

/proc/get_headshot_icon(mob/living/carbon/human/target, size = 64, crop_height = 32)
	if(!target || !istype(target))
		return ""

	var/datum/weakref/weak_target = WEAKREF(target)
	var/cache_key = weak_target
	var/appearance_signature = "[target.icon]-[target.icon_state]-[length(target.overlays)]-[length(target.underlays)]-[target.color]"

	var/list/cache_entry = GLOB.headshot_cache[cache_key]
	if(cache_entry)
		var/mob/living/cached_target = weak_target.resolve()
		if(cached_target && cache_entry["signature"] == appearance_signature)
			return cache_entry["html"]
		else
			GLOB.headshot_cache -= cache_key

	target.update_inv_hands()
	target.update_inv_belt()
	target.update_inv_back()
	target.update_inv_head()
	// Better include this later uh oh!
	// var/was_typing = target.typing
	// if(was_typing)
	// 	target.set_typing_indicator(FALSE)

	var/image/dummy = image(target.icon, target, target.icon_state, target.layer, target.dir)
	dummy.appearance = target.appearance
	dummy.dir = SOUTH

	target.update_inv_hands()
	target.update_inv_belt()
	target.update_inv_back()
	target.update_inv_head()
	// if(was_typing)
	// 	target.set_typing_indicator(TRUE)

	var/icon/headshot = getFlatIcon(dummy, SOUTH, no_anim = TRUE)
	headshot.Scale(size, size)
	headshot.Crop(1, size - crop_height + 1, size, size)

	var/icon_html = "<img src='data:image/png;base64,[icon2base64(headshot)]' style='width:[size]px;height:[crop_height]px;image-rendering:pixelated;'>"

	if(length(GLOB.headshot_cache) >= 200)
		var/num_to_remove = round(200 * 0.15)
		for(var/i in 1 to num_to_remove)
			GLOB.headshot_cache.Cut(1, 2)

	GLOB.headshot_cache[cache_key] = list(
		"signature" = appearance_signature,
		"html" = icon_html
	)
	return icon_html


var/global/character_setup_preview_debug_logging = TRUE
var/global/list/preview_icon_opaque_bounds_cache = list()
var/global/list/preview_icon_row_bounds_cache = list()
var/global/list/preview_icon_row_segments_cache = list()

/proc/get_preview_icon_cache_key(icon/source_icon)
	if(!source_icon)
		return null
	var/rsc_ref = source_icon.RscFile()
	if(!rsc_ref || !length("[rsc_ref]"))
		return null
	return "[rsc_ref]|[source_icon.Width()]x[source_icon.Height()]"

/proc/preview_icon_pixel_is_opaque(pixel)
	if(isnull(pixel) || !length("[pixel]"))
		return FALSE
	var/text_pixel = "[pixel]"
	if(length(text_pixel) >= 9)
		var/alpha_hex = copytext(text_pixel, 8, 10)
		if(length(alpha_hex) >= 2)
			return text2num("0x[alpha_hex]") > 0
	return TRUE

/proc/get_preview_icon_opaque_bounds(icon/source_icon)
	if(!source_icon)
		return null
	var/cache_key = get_preview_icon_cache_key(source_icon)
	var/list/cached_bounds = cache_key ? preview_icon_opaque_bounds_cache[cache_key] : null
	if(cached_bounds)
		return cached_bounds
	var/min_x = 0
	var/max_x = 0
	var/min_y = 0
	var/max_y = 0
	for(var/y = 1 to source_icon.Height())
		for(var/x = 1 to source_icon.Width())
			if(!preview_icon_pixel_is_opaque(source_icon.GetPixel(x, y)))
				continue
			if(!min_x || x < min_x)
				min_x = x
			if(!max_x || x > max_x)
				max_x = x
			if(!min_y || y < min_y)
				min_y = y
			if(!max_y || y > max_y)
				max_y = y
	if(!min_x || !max_x || !min_y || !max_y)
		return null
	var/list/bounds = list(
		"left" = min_x,
		"right" = max_x,
		"bottom" = min_y,
		"top" = max_y,
	)
	if(cache_key)
		preview_icon_opaque_bounds_cache[cache_key] = bounds
	return bounds

/proc/get_preview_icon_row_bounds(icon/source_icon, y)
	if(!source_icon || y < 1 || y > source_icon.Height())
		return null
	var/cache_key = get_preview_icon_cache_key(source_icon)
	var/row_cache_key = cache_key ? "[cache_key]|row_bounds|[y]" : null
	var/list/cached_row_bounds = row_cache_key ? preview_icon_row_bounds_cache[row_cache_key] : null
	if(cached_row_bounds)
		return cached_row_bounds
	var/row_left = 0
	var/row_right = 0
	for(var/x = 1 to source_icon.Width())
		if(!preview_icon_pixel_is_opaque(source_icon.GetPixel(x, y)))
			continue
		if(!row_left)
			row_left = x
		row_right = x
	if(!row_left || !row_right)
		return null
	var/list/row_bounds = list(
		"left" = row_left,
		"right" = row_right,
	)
	if(row_cache_key)
		preview_icon_row_bounds_cache[row_cache_key] = row_bounds
	return row_bounds

/proc/get_preview_icon_row_segments(icon/source_icon, y)
	if(!source_icon || y < 1 || y > source_icon.Height())
		return null
	var/cache_key = get_preview_icon_cache_key(source_icon)
	var/row_cache_key = cache_key ? "[cache_key]|row_segments|[y]" : null
	var/list/cached_segments = row_cache_key ? preview_icon_row_segments_cache[row_cache_key] : null
	if(cached_segments)
		return cached_segments
	var/list/segments = list()
	var/segment_left = 0
	for(var/x = 1 to source_icon.Width())
		var/is_opaque = preview_icon_pixel_is_opaque(source_icon.GetPixel(x, y))
		if(is_opaque)
			if(!segment_left)
				segment_left = x
			continue
		if(segment_left)
			segments += list(list("left" = segment_left, "right" = x - 1))
			segment_left = 0
	if(segment_left)
		segments += list(list("left" = segment_left, "right" = source_icon.Width()))
	if(row_cache_key && segments.len)
		preview_icon_row_segments_cache[row_cache_key] = segments
	return segments.len ? segments : null

/proc/get_preview_icon_support_bounds(icon/source_icon, y, preferred_center = 0)
	var/list/segments = get_preview_icon_row_segments(source_icon, y)
	if(!segments || !segments.len)
		return null

	var/list/merged_segments = list()
	var/list/current_segment = null
	for(var/i = 1 to segments.len)
		var/list/segment = segments[i]
		if(!current_segment)
			current_segment = list("left" = segment["left"], "right" = segment["right"])
			continue
		if(segment["left"] - current_segment["right"] <= 3)
			current_segment["right"] = segment["right"]
			continue
		merged_segments += list(current_segment)
		current_segment = list("left" = segment["left"], "right" = segment["right"])
	if(current_segment)
		merged_segments += list(current_segment)

	var/list/best_segment = null
	var/best_score = null
	for(var/i = 1 to merged_segments.len)
		var/list/segment = merged_segments[i]
		var/width = segment["right"] - segment["left"] + 1
		if(width < 2)
			continue
		if(width > 20)
			continue
		var/center = (segment["left"] + segment["right"]) / 2
		var/score = min(width, 10) * 6
		if(preferred_center)
			score -= abs(center - preferred_center) * 12
		if(isnull(best_score) || score > best_score)
			best_score = score
			best_segment = segment
	if(best_segment)
		return best_segment
	return get_preview_icon_row_bounds(source_icon, y)

/proc/preview_debug_dir_name(direction)
	if(direction == NORTH)
		return "NORTH"
	if(direction == SOUTH)
		return "SOUTH"
	if(direction == EAST)
		return "EAST"
	if(direction == WEST)
		return "WEST"
	return "[direction]"

/proc/preview_debug_segments_to_text(list/segments)
	if(!segments || !segments.len)
		return "[]"
	var/list/parts = list()
	for(var/i = 1 to segments.len)
		var/list/segment = segments[i]
		var/left = segment["left"]
		var/right = segment["right"]
		parts += "[left]-[right]"
	var/parts_text = jointext(parts, ", ")
	return parts_text

/proc/preview_debug_log(message)
	if(!character_setup_preview_debug_logging)
		return
	var/timestamp = time2text(world.realtime, "YYYY-MM-DD hh:mm:ss")
	log_game("[timestamp] [message]")

/proc/get_preview_icon_body_anchor(icon/source_icon, preview_dir = SOUTH, debug_context = null, debug_dir = null)
	if(!source_icon)
		return null
	var/list/bounds = get_preview_icon_opaque_bounds(source_icon)
	if(!bounds)
		if(debug_context)
			preview_debug_log("[debug_context] dir=[preview_debug_dir_name(debug_dir)] no_opaque_bounds")
		return null

	var/bounds_left = bounds["left"]
	var/bounds_right = bounds["right"]
	var/bounds_bottom = bounds["bottom"]
	var/bounds_top = bounds["top"]
	if(debug_context)
		preview_debug_log("[debug_context] dir=[preview_debug_dir_name(debug_dir)] icon=[source_icon.Width()]x[source_icon.Height()] bounds=([bounds_left],[bounds_bottom])-([bounds_right],[bounds_top])")

	var/list/head_centers = list()
	var/head_start
	var/head_end
	if((preview_dir == EAST || preview_dir == WEST) && source_icon.Width() >= 64)
		head_start = max(bounds["bottom"], bounds["top"] - 14)
		head_end = max(head_start, bounds["top"] - 4)
	else
		head_start = max(bounds["bottom"], bounds["top"] - 8)
		head_end = bounds["top"]
	var/last_head_center = 0
	for(var/y = head_start to head_end)
		var/list/head_segments = get_preview_icon_row_segments(source_icon, y)
		if(!head_segments || !head_segments.len)
			continue

		var/list/head_candidates = list()
		for(var/i = 1 to head_segments.len)
			var/list/segment = head_segments[i]
			var/segment_width = segment["right"] - segment["left"] + 1
			if(segment_width < 2)
				continue
			if(segment_width > 10)
				continue
			head_candidates += list(segment)
		if(!head_candidates.len)
			continue

		var/list/best_head_segment = null
		var/best_head_score = null
		var/head_row_mid = (bounds["left"] + bounds["right"]) / 2
		for(var/i = 1 to head_candidates.len)
			var/list/segment = head_candidates[i]
			var/segment_width = segment["right"] - segment["left"] + 1
			var/segment_center = (segment["left"] + segment["right"]) / 2
			var/score = abs(segment_center - head_row_mid) * 10 + segment_width
			if(preview_dir == EAST)
				score -= segment["right"] * 2
			else if(preview_dir == WEST)
				score += segment["left"] * 2
			if(last_head_center)
				score += abs(segment_center - last_head_center) * 8
			if(isnull(best_head_score) || score < best_head_score)
				best_head_score = score
				best_head_segment = segment

		if(!best_head_segment)
			continue
		var/head_center = (best_head_segment["left"] + best_head_segment["right"]) / 2
		head_centers += head_center
		last_head_center = head_center

	var/head_seed_center = 0
	if(head_centers.len)
		var/head_sum = 0
		for(var/value in head_centers)
			head_sum += value
		head_seed_center = round(head_sum / head_centers.len)
		if(debug_context)
			preview_debug_log("[debug_context] dir=[preview_debug_dir_name(debug_dir)] head_rows=[head_start]-[head_end] head_centers=[jointext(head_centers, ",")] head_seed=[head_seed_center]")

	var/list/core_centers = list()
	var/torso_start = min(bounds["top"], bounds["bottom"] + 8)
	var/torso_end = min(bounds["top"], bounds["bottom"] + 22)
	var/last_core_center = head_seed_center
	for(var/y = torso_start to torso_end)
		var/list/row_segments = get_preview_icon_row_segments(source_icon, y)
		if(!row_segments || !row_segments.len)
			continue

		var/list/candidates = list()
		for(var/i = 1 to row_segments.len)
			var/list/segment = row_segments[i]
			var/segment_width = segment["right"] - segment["left"] + 1
			if(segment_width < 4)
				continue
			if(segment_width > 12)
				continue
			candidates += list(segment)
		if(!candidates.len)
			continue

		var/list/best_segment = null
		var/row_mid = (bounds["left"] + bounds["right"]) / 2
		var/seed_center = last_core_center
		if(!seed_center)
			seed_center = head_seed_center
		if(!seed_center)
			seed_center = row_mid
		var/best_score = null
		for(var/i = 1 to candidates.len)
			var/list/segment = candidates[i]
			var/segment_width = segment["right"] - segment["left"] + 1
			var/segment_center = (segment["left"] + segment["right"]) / 2
			var/score = abs(segment_center - seed_center) * 10 + segment_width
			if(preview_dir == EAST && head_seed_center)
				if(segment_center < head_seed_center - 2)
					score += (head_seed_center - segment_center) * 8
				else
					score += abs(segment_center - head_seed_center) * 2
			else if(preview_dir == WEST && head_seed_center)
				if(segment_center > head_seed_center + 2)
					score += (segment_center - head_seed_center) * 8
				else
					score += abs(segment_center - head_seed_center) * 2
			else
				score += abs(segment_center - row_mid) * 2
			if(isnum(last_core_center) && last_core_center)
				score += abs(segment_center - last_core_center) * 5
			if(isnull(best_score) || score < best_score)
				best_score = score
				best_segment = segment

		if(!best_segment)
			continue
		var/row_center = (best_segment["left"] + best_segment["right"]) / 2
		if((preview_dir == SOUTH || preview_dir == NORTH) && core_centers.len >= 2 && last_core_center && abs(row_center - last_core_center) > 4)
			if(debug_context)
				preview_debug_log("[debug_context] dir=[preview_debug_dir_name(debug_dir)] y=[y] reject=torso_outlier row_center=[row_center] last_core_center=[last_core_center]")
			continue
		core_centers += row_center
		last_core_center = row_center

	var/preferred_center = round((bounds["left"] + bounds["right"]) / 2)
	if(core_centers.len)
		var/center_sum = 0
		for(var/value in core_centers)
			center_sum += value
		preferred_center = round(center_sum / core_centers.len)

	if((preview_dir == EAST || preview_dir == WEST) && source_icon.Width() >= 96 && core_centers.len >= 2)
		var/min_core_center = core_centers[1]
		var/max_core_center = core_centers[1]
		for(var/value in core_centers)
			if(value < min_core_center)
				min_core_center = value
			if(value > max_core_center)
				max_core_center = value
		if(max_core_center - min_core_center >= 8)
			var/old_preferred_center = preferred_center
			if(preview_dir == WEST)
				preferred_center = round(max_core_center)
			else
				preferred_center = round(min_core_center)
			if(debug_context)
				preview_debug_log("[debug_context] dir=[preview_debug_dir_name(debug_dir)] side_cluster_recenter old_preferred_center=[old_preferred_center] min_core=[min_core_center] max_core=[max_core_center] new_preferred_center=[preferred_center]")

	if((preview_dir == SOUTH || preview_dir == NORTH) && source_icon.Width() >= 64 && head_seed_center && preferred_center < head_seed_center - 5)
		var/old_preferred_center = preferred_center
		preferred_center = max(preferred_center, head_seed_center - 2)
		if(debug_context)
			preview_debug_log("[debug_context] dir=[preview_debug_dir_name(debug_dir)] front_headseed_recenter old_preferred_center=[old_preferred_center] head_seed=[head_seed_center] new_preferred_center=[preferred_center]")
	if(debug_context)
		var/core_text = core_centers.len ? jointext(core_centers, ",") : "none"
		preview_debug_log("[debug_context] dir=[preview_debug_dir_name(debug_dir)] torso_rows=[torso_start]-[torso_end] core_centers=[core_text] preferred_center=[preferred_center]")

	var/list/foot_centers = list()
	var/list/foot_rows = list()
	var/search_top = min(bounds["top"], bounds["bottom"] + 20)
	var/started = FALSE
	var/last_center = 0
	var/support_window_left = max(1, preferred_center - 5)
	var/support_window_right = min(source_icon.Width(), preferred_center + 5)
	var/broad_side_support_mode = FALSE
	if((preview_dir == EAST || preview_dir == WEST) && source_icon.Width() >= 96)
		for(var/probe_y = bounds["bottom"] to search_top)
			var/list/probe_segments = get_preview_icon_row_segments(source_icon, probe_y)
			if(!probe_segments || !probe_segments.len)
				continue
			var/probe_has_core = FALSE
			var/probe_has_side = FALSE
			for(var/i = 1 to probe_segments.len)
				var/list/probe_segment = probe_segments[i]
				var/probe_left = probe_segment["left"]
				var/probe_right = probe_segment["right"]
				var/probe_width = probe_right - probe_left + 1
				var/probe_overlap_left = max(probe_left, support_window_left)
				var/probe_overlap_right = min(probe_right, support_window_right)
				if(probe_overlap_left <= probe_overlap_right && probe_overlap_right - probe_overlap_left + 1 >= 1)
					probe_has_core = TRUE
				else if(probe_width >= 2 && probe_right < support_window_left && support_window_left - probe_right <= 20)
					probe_has_side = TRUE
			if(probe_has_core && probe_has_side)
				broad_side_support_mode = TRUE
				break
	if(debug_context)
		preview_debug_log("[debug_context] dir=[preview_debug_dir_name(debug_dir)] foot_search=[bounds_bottom]-[search_top] support_window=[support_window_left]-[support_window_right] broad_side_support=[broad_side_support_mode]")
	for(var/y = bounds["bottom"] to search_top)
		var/list/segments = get_preview_icon_row_segments(source_icon, y)
		if(debug_context)
			preview_debug_log("[debug_context] dir=[preview_debug_dir_name(debug_dir)] y=[y] segments=[preview_debug_segments_to_text(segments)] started=[started]")
		if(!segments || !segments.len)
			if(started)
				if(debug_context)
					preview_debug_log("[debug_context] dir=[preview_debug_dir_name(debug_dir)] y=[y] stop=no_segments_after_start")
				break
			continue

		var/support_left = 0
		var/support_right = 0
		var/extra_support_left = 0
		var/extra_support_right = 0
		var/min_overlap_width = broad_side_support_mode ? 1 : 2
		for(var/i = 1 to segments.len)
			var/list/segment = segments[i]
			var/segment_left = segment["left"]
			var/segment_right = segment["right"]
			var/segment_width = segment_right - segment_left + 1
			var/overlap_left = max(segment_left, support_window_left)
			var/overlap_right = min(segment_right, support_window_right)
			if(overlap_left <= overlap_right && overlap_right - overlap_left + 1 >= min_overlap_width)
				if(!support_left || overlap_left < support_left)
					support_left = overlap_left
				if(!support_right || overlap_right > support_right)
					support_right = overlap_right
				continue
			if(broad_side_support_mode && segment_width >= 2 && segment_right < support_window_left && support_window_left - segment_right <= 20)
				if(!extra_support_left || segment_left < extra_support_left)
					extra_support_left = segment_left
				if(!extra_support_right || segment_right > extra_support_right)
					extra_support_right = segment_right

		if(broad_side_support_mode)
			if(support_left && support_right && extra_support_left && extra_support_right)
				support_left = min(support_left, extra_support_left)
				support_right = max(support_right, extra_support_right)
			else if(!started && (!extra_support_left || !extra_support_right))
				if(debug_context)
					preview_debug_log("[debug_context] dir=[preview_debug_dir_name(debug_dir)] y=[y] skip=waiting_for_broad_support")
				continue

		if(debug_context)
			preview_debug_log("[debug_context] dir=[preview_debug_dir_name(debug_dir)] y=[y] support=[support_left]-[support_right]")
		if(!support_left || !support_right)
			if(started)
				if(debug_context)
					preview_debug_log("[debug_context] dir=[preview_debug_dir_name(debug_dir)] y=[y] stop=no_support_after_start")
				break
			continue

		var/row_width = support_right - support_left + 1
		if(row_width < 2)
			if(debug_context)
				preview_debug_log("[debug_context] dir=[preview_debug_dir_name(debug_dir)] y=[y] reject=row_width_lt_2")
			if(started)
				break
			continue
		var/max_row_width = broad_side_support_mode ? 24 : 12
		if(row_width > max_row_width)
			if(debug_context)
				preview_debug_log("[debug_context] dir=[preview_debug_dir_name(debug_dir)] y=[y] reject=row_width_gt_[max_row_width] width=[row_width]")
			if(started)
				break
			continue

		var/row_center = (support_left + support_right) / 2
		if(debug_context)
			preview_debug_log("[debug_context] dir=[preview_debug_dir_name(debug_dir)] y=[y] row_width=[row_width] row_center=[row_center] preferred_center=[preferred_center] last_center=[last_center]")
		if(!broad_side_support_mode && abs(row_center - preferred_center) > 4)
			if(debug_context)
				preview_debug_log("[debug_context] dir=[preview_debug_dir_name(debug_dir)] y=[y] reject=center_far diff=[abs(row_center - preferred_center)]")
			if(started)
				break
			continue
		var/max_center_jump = broad_side_support_mode ? 6 : 3
		if(started && abs(row_center - last_center) > max_center_jump)
			if(debug_context)
				preview_debug_log("[debug_context] dir=[preview_debug_dir_name(debug_dir)] y=[y] stop=center_jump diff=[abs(row_center - last_center)]")
			break
		started = TRUE
		foot_centers += row_center
		foot_rows += y
		last_center = row_center
		if(debug_context)
			preview_debug_log("[debug_context] dir=[preview_debug_dir_name(debug_dir)] y=[y] accept center=[row_center]")
		if(foot_rows.len >= 6)
			break

	var/anchor_x = preferred_center
	var/body_bottom_y = bounds["bottom"]
	if(foot_centers.len)
		var/foot_sum = 0
		for(var/value in foot_centers)
			foot_sum += value
		anchor_x = round(foot_sum / foot_centers.len)
		if(!broad_side_support_mode)
			if(anchor_x < preferred_center - 2)
				anchor_x = preferred_center - 2
			else if(anchor_x > preferred_center + 2)
				anchor_x = preferred_center + 2
		else if(debug_context)
			preview_debug_log("[debug_context] dir=[preview_debug_dir_name(debug_dir)] broad_support_unclamped anchor_x=[anchor_x] preferred_center=[preferred_center]")
		body_bottom_y = foot_rows[1]
	else
		anchor_x = preferred_center
		body_bottom_y = max(bounds["bottom"], torso_start - 5)
	if(debug_context)
		var/foot_center_text = foot_centers.len ? jointext(foot_centers, ",") : "none"
		var/foot_row_text = foot_rows.len ? jointext(foot_rows, ",") : "none"
		preview_debug_log("[debug_context] dir=[preview_debug_dir_name(debug_dir)] foot_centers=[foot_center_text] foot_rows=[foot_row_text] final_anchor_x=[anchor_x] final_bottom_y=[body_bottom_y]")

	return list(
		"anchor_x" = anchor_x,
		"bottom_y" = body_bottom_y,
	)

/proc/build_fixed_character_setup_full_preview_icon(icon/source_icon, preview_dir = SOUTH, canvas_width = 32, canvas_height = 40, target_anchor_x = 16, target_bottom_y = 3, debug_context = null, debug_dir = null)
	if(!source_icon)
		return null

	var/list/body_anchor = get_preview_icon_body_anchor(source_icon, preview_dir, debug_context, debug_dir)
	if(!body_anchor)
		if(debug_context)
			preview_debug_log("[debug_context] dir=[preview_debug_dir_name(debug_dir)] body_anchor=null returning_source_icon")
		return source_icon

	var/icon/result_icon = icon('icons/effects/effects.dmi', "nothing")
	result_icon.Scale(canvas_width, canvas_height)

	var/blend_x = round(target_anchor_x - body_anchor["anchor_x"] + 1)
	var/blend_y = round(target_bottom_y - body_anchor["bottom_y"] + 1)

	var/list/opaque_bounds = get_preview_icon_opaque_bounds(source_icon)
	if(opaque_bounds)
		var/source_width = source_icon.Width()
		var/bounds_width = opaque_bounds["right"] - opaque_bounds["left"] + 1
		if(preview_dir == EAST || preview_dir == WEST)
			if(source_width == 64 && bounds_width >= 22 && bounds_width <= 32)
				if(debug_context)
					preview_debug_log("[debug_context] dir=[preview_debug_dir_name(debug_dir)] side_compensation=0 skipped_for_64wide source_width=[source_width] bounds_width=[bounds_width] blend_x=[blend_x]")
		else if(preview_dir == SOUTH || preview_dir == NORTH)
			if(source_width == 64 && bounds_width >= 30)
				if(body_anchor["anchor_x"] <= round(source_width * 0.5))
					blend_x -= 7
					if(debug_context)
						preview_debug_log("[debug_context] dir=[preview_debug_dir_name(debug_dir)] front_medium_wide_compensation=7 source_width=[source_width] bounds_width=[bounds_width] anchor_x=[body_anchor["anchor_x"]] blend_x=[blend_x]")
				else
					blend_x += 9
					if(debug_context)
						preview_debug_log("[debug_context] dir=[preview_debug_dir_name(debug_dir)] front_right_anchor_compensation=9 source_width=[source_width] bounds_width=[bounds_width] anchor_x=[body_anchor["anchor_x"]] blend_x=[blend_x]")
			else if(source_width >= 96 && bounds_width >= 24 && bounds_width <= 32)
				if(debug_context)
					preview_debug_log("[debug_context] dir=[preview_debug_dir_name(debug_dir)] front_wide_compensation=0 skipped_for_96wide source_width=[source_width] bounds_width=[bounds_width] blend_x=[blend_x]")
	if(debug_context)
		preview_debug_log("[debug_context] dir=[preview_debug_dir_name(debug_dir)] target_anchor_x=[target_anchor_x] target_bottom_y=[target_bottom_y] blend_x=[blend_x] blend_y=[blend_y]")
	result_icon.Blend(source_icon, ICON_OVERLAY, blend_x, blend_y)
	return result_icon


/proc/get_preview_icon_numeric_median(list/values)
	if(!values || !values.len)
		return null
	var/list/sorted_values = list()
	for(var/value in values)
		var/numeric_value = text2num("[value]")
		var/inserted = FALSE
		for(var/i = 1 to sorted_values.len)
			if(numeric_value < text2num("[sorted_values[i]]"))
				sorted_values.Insert(i, numeric_value)
				inserted = TRUE
				break
		if(!inserted)
			sorted_values += numeric_value
	if(sorted_values.len % 2)
		var/middle = (sorted_values.len + 1) / 2
		return text2num("[sorted_values[middle]]")
	var/lower_middle = sorted_values.len / 2
	return (text2num("[sorted_values[lower_middle]]") + text2num("[sorted_values[lower_middle + 1]]")) / 2


/proc/get_preview_icon_head_seed_center(icon/source_icon, debug_context = null, debug_dir = null)
	if(!source_icon)
		return null
	var/list/bounds = get_preview_icon_opaque_bounds(source_icon)
	if(!bounds)
		if(debug_context)
			preview_debug_log("[debug_context] dir=[preview_debug_dir_name(debug_dir)] head_seed_bounds=null")
		return null

	var/head_top = bounds["top"]
	var/head_bottom = max(bounds["bottom"], head_top - 8)
	var/list/head_centers = list()
	var/list/preferred_head_centers = list()
	var/max_segment_width = 0
	for(var/y = head_bottom to head_top)
		var/list/segments = get_preview_icon_row_segments(source_icon, y)
		if(!segments || !segments.len)
			continue
		var/list/best_segment = null
		var/best_width = 0
		for(var/i = 1 to segments.len)
			var/list/segment = segments[i]
			var/width = segment["right"] - segment["left"] + 1
			if(width > best_width)
				best_width = width
				best_segment = segment
		if(!best_segment)
			continue
		var/center = (best_segment["left"] + best_segment["right"]) / 2
		head_centers += center
		if(best_width > max_segment_width)
			max_segment_width = best_width

	if(!head_centers.len)
		return null

	var/preferred_min_width = max(2, round(max_segment_width * 0.65))
	for(var/y = head_bottom to head_top)
		var/list/segments = get_preview_icon_row_segments(source_icon, y)
		if(!segments || !segments.len)
			continue
		var/list/best_segment = null
		var/best_width = 0
		for(var/i = 1 to segments.len)
			var/list/segment = segments[i]
			var/width = segment["right"] - segment["left"] + 1
			if(width > best_width)
				best_width = width
				best_segment = segment
		if(!best_segment || best_width < preferred_min_width)
			continue
		preferred_head_centers += (best_segment["left"] + best_segment["right"]) / 2

	var/head_seed = get_preview_icon_numeric_median(preferred_head_centers.len ? preferred_head_centers : head_centers)
	if(debug_context)
		preview_debug_log("[debug_context] dir=[preview_debug_dir_name(debug_dir)] head_seed_rows=[head_bottom]-[head_top] head_seed_centers=[jointext(head_centers, ",")] preferred_centers=[jointext(preferred_head_centers, ",")] preferred_min_width=[preferred_min_width] max_segment_width=[max_segment_width] head_seed=[head_seed]")
	return head_seed

/proc/get_character_setup_head_crop_width(preview_dir)
	if(preview_dir == EAST || preview_dir == WEST)
		return 20
	return 16

/proc/get_character_setup_head_band_width(preview_dir)
	if(preview_dir == EAST || preview_dir == WEST)
		return 22
	return 18

/proc/get_character_setup_head_band_height(preview_dir)
	return 16

/proc/get_character_setup_head_feature_crop_box(source_width, source_height, preview_dir = SOUTH)
	var/crop_width = min(get_character_setup_head_band_width(preview_dir), source_width)
	var/crop_height = min(get_character_setup_head_band_height(preview_dir), source_height)
	var/center_x = round((source_width + 1) / 2)
	if(preview_dir == EAST)
		center_x += 1
	else if(preview_dir == WEST)
		center_x -= 1

	var/max_left = max(1, source_width - crop_width + 1)
	var/crop_left = clamp(round(center_x - ((crop_width - 1) / 2)), 1, max_left)
	var/crop_right = min(source_width, crop_left + crop_width - 1)
	var/crop_top = source_height
	var/crop_bottom = max(1, crop_top - crop_height + 1)
	return list(
		"left" = crop_left,
		"right" = crop_right,
		"bottom" = crop_bottom,
		"top" = crop_top,
		"width" = crop_width,
		"height" = crop_height,
	)

/proc/extract_character_setup_head_features_icon(icon/source_icon, preview_dir = SOUTH, debug_context = null, debug_dir = null)
	if(!source_icon)
		return null

	var/icon/result_icon = icon(source_icon)
	var/source_width = result_icon.Width()
	var/source_height = result_icon.Height()
	if(source_width <= 0 || source_height <= 0)
		return result_icon

	var/list/crop_box = get_character_setup_head_feature_crop_box(source_width, source_height, preview_dir)
	var/crop_left = crop_box["left"]
	var/crop_right = crop_box["right"]
	var/crop_bottom = crop_box["bottom"]
	var/crop_top = crop_box["top"]

	if(debug_context)
		preview_debug_log("[debug_context] dir=[preview_debug_dir_name(debug_dir)] head_feature_band crop=([crop_left],[crop_bottom])-([crop_right],[crop_top]) source=[source_width]x[source_height]")

	result_icon.Crop(crop_left, crop_bottom, crop_right, crop_top)
	return result_icon

/proc/build_centered_character_setup_head_preview_icon(icon/source_icon, crop_y1 = 18, crop_y2 = 32, crop_width = 16, debug_context = null, debug_dir = null)
	if(!source_icon)
		return null

	var/icon/result_icon = icon(source_icon)
	var/source_width = result_icon.Width()
	var/source_height = result_icon.Height()
	if(source_width < crop_width || source_height < crop_y1)
		result_icon.Crop(max(1, source_width - crop_width + 1), max(1, min(crop_y1, source_height)), source_width, min(crop_y2, source_height))
		return result_icon

	var/head_seed = get_preview_icon_head_seed_center(result_icon, debug_context, debug_dir)
	if(isnull(head_seed))
		var/list/bounds = get_preview_icon_opaque_bounds(result_icon)
		if(bounds)
			head_seed = (bounds["left"] + bounds["right"]) / 2
		else
			head_seed = 16

	var/max_left = max(1, source_width - crop_width + 1)
	var/crop_left = clamp(round(head_seed - ((crop_width - 1) / 2)), 1, max_left)
	var/crop_right = crop_left + crop_width - 1
	var/crop_bottom = clamp(crop_y1, 1, source_height)
	var/crop_top = clamp(crop_y2, crop_bottom, source_height)
	if(debug_context)
		preview_debug_log("[debug_context] dir=[preview_debug_dir_name(debug_dir)] head_focus head_seed=[head_seed] crop=([crop_left],[crop_bottom])-([crop_right],[crop_top]) source=[source_width]x[source_height]")
	result_icon.Crop(crop_left, crop_bottom, crop_right, crop_top)
	return result_icon
