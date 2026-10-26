extends SceneTree

func _initialize() -> void:
	var text = Engine.get_license_text() + "\n\nTHIRD PARTY COPYRIGHTS\n"
	for entry in Engine.get_copyright_info():
		text += "\n" + entry.name + "\n"
		for part in entry.parts:
			text += "Files: " + ", ".join(part.files) + "\n"
			text += "Copyright: " + "; ".join(part.copyright) + "\nLicense: " + part.license + "\n"
	text += "\nFULL LICENSE TEXTS\n"
	var licenses = Engine.get_license_info()
	for name in licenses:
		text += "\n" + name + "\n" + licenses[name] + "\n"
	var file = FileAccess.open("res://GODOT_COPYRIGHT.txt", FileAccess.WRITE)
	file.store_string(text)
	print("Wrote runtime dependency notices")
	quit()
