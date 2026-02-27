"""JSON writer — serializes ProjectData to a JSON file."""

from ..types.project import ProjectData


fn write_json_file(data: ProjectData, output_path: String) raises:
    """Write ProjectData as JSON to the specified output file."""
    from python import Python

    var json_str = data.to_json()

    # Use Python's file I/O for reliable file writing
    var builtins = Python.import_module("builtins")
    var f = builtins.open(String(output_path), "w", encoding="utf-8")
    f.write(json_str)
    f.close()


fn write_json_pretty(data: ProjectData, output_path: String) raises:
    """Write ProjectData as pretty-printed JSON to the specified output file."""
    from python import Python

    var json_str = data.to_json()

    # Parse and re-dump with indentation via Python's json module
    var json_mod = Python.import_module("json")
    var parsed = json_mod.loads(json_str)
    var pretty = json_mod.dumps(parsed, indent=2, ensure_ascii=False)

    var builtins = Python.import_module("builtins")
    var f = builtins.open(String(output_path), "w", encoding="utf-8")
    f.write(pretty)
    f.close()
