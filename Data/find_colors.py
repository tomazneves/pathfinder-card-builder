from PIL import Image
import json

def rgb_to_hex(r, g, b):
    """Converts RGB values to a 6-character hex string."""
    return f"{r:02x}{g:02x}{b:02x}".upper()

def get_icon_colors(image_path, names_path):
    # Load the names from the text file
    with open(names_path, 'r') as f:
        names = [line.strip() for line in f if line.strip()]

    # Open the image and ensure it's in RGBA mode for transparency support
    img = Image.open(image_path).convert("RGBA")
    width, height = img.size
    
    # Calculate the dimensions of each cell in the 10x10 grid
    cols, rows = 10, 10
    cell_w = width // cols
    cell_h = height // rows

    trait_colors = {}

    for i, name in enumerate(names):
        col = i % cols
        row = i // cols
        
        # Crop the image to the specific grid section for the current icon
        left = col * cell_w
        top = row * cell_h
        right = (col + 1) * cell_w
        bottom = (row + 1) * cell_h
        cell = img.crop((left, top, right, bottom))
        
        # Get all colors in the cropped cell
        colors = cell.getcolors(cell_w * cell_h)
        
        valid_colors = []
        for count, (r, g, b, a) in colors:
            # Filter out fully transparent pixels
            if a == 0:
                continue
            # Filter out white/near-white pixels (the background)
            if r > 240 and g > 240 and b > 240:
                continue
                
            valid_colors.append((count, (r, g, b)))
        
        # Determine the most frequent color remaining
        if valid_colors:
            # Sort by frequency (count) in descending order
            valid_colors.sort(key=lambda x: x[0], reverse=True)
            most_frequent_rgb = valid_colors[0][1]
            trait_colors[name] = rgb_to_hex(*most_frequent_rgb)
        else:
            # Fallback if the icon is empty or purely white/transparent
            trait_colors[name] = "FFFFFF" 

    return trait_colors

def split_icons(image_path, output_dir, names_path):
    # Load the names from the text file
    with open(names_path, 'r') as f:
        names = [line.strip() for line in f if line.strip()]

    # Open the image and ensure it's in RGBA mode for transparency support
    img = Image.open(image_path).convert("RGBA")
    width, height = img.size
    
    # Calculate the dimensions of each cell in the 10x10 grid
    cols, rows = 10, 10
    cell_w = width // cols
    cell_h = height // rows

    for i, name in enumerate(names):
        col = i % cols
        row = i // cols
        
        # Crop the image to the specific grid section for the current icon
        left = col * cell_w
        top = row * cell_h
        right = (col + 1) * cell_w
        bottom = (row + 1) * cell_h
        cell = img.crop((left, top, right, bottom))
        
        # Save the cropped icon to the output directory with the name as filename
        output_path = f"{output_dir}/{name}.png"
        cell.save(output_path)

if __name__ == "__main__":
    image_file = "Data/trait-icons.png"
    names_file = "Data/traits.txt"
    colors_file = "Data/trait_colors.json"
    try:
        colors_dict = get_icon_colors(image_file, names_file)
        
        # Output the resulting dictionary
        print("trait_colors = {")
        for name, hex_code in colors_dict.items():
            print(f'    "{name}": "{hex_code}",')
        print("}")

        with open(colors_file, 'w') as f:
            json.dump(colors_dict, f, indent=4)

        split_icons(image_file, "Data/Icons", names_file)
        
    except FileNotFoundError as e:
        print(f"Error: {e}. Please ensure '{image_file}' and '{names_file}' are in the directory.")