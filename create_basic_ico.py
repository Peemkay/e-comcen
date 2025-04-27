"""
Create a basic ICO file with the NASDS colors.
"""
import os
from PIL import Image, ImageDraw

def create_icon(size, output_path):
    """Create a simple icon with NASDS colors."""
    # Create a new image with a navy blue background (#00205B)
    img = Image.new('RGBA', (size, size), (0, 32, 91, 255))
    draw = ImageDraw.Draw(img)
    
    # Draw a white circle
    padding = size // 12
    draw.ellipse(
        [(padding, padding), (size - padding, size - padding)],
        fill=(255, 255, 255, 255)
    )
    
    # Draw a smaller navy blue circle
    inner_padding = size // 6
    draw.ellipse(
        [(inner_padding, inner_padding), (size - inner_padding, size - inner_padding)],
        fill=(0, 32, 91, 255)
    )
    
    # Draw a green envelope in the center
    envelope_width = size // 2
    envelope_height = envelope_width * 0.8
    envelope_left = (size - envelope_width) // 2
    envelope_top = (size - envelope_height) // 2
    
    # Envelope body (green)
    draw.rectangle(
        [(envelope_left, envelope_top), (envelope_left + envelope_width, envelope_top + envelope_height)],
        fill=(0, 128, 0, 255),
        outline=(255, 215, 0, 255)  # Gold outline
    )
    
    # Envelope flap (triangle at the top)
    draw.polygon(
        [
            (envelope_left, envelope_top),
            (envelope_left + envelope_width // 2, envelope_top - envelope_height // 4),
            (envelope_left + envelope_width, envelope_top)
        ],
        fill=(0, 128, 0, 255),
        outline=(255, 215, 0, 255)  # Gold outline
    )
    
    return img

def main():
    # Paths for the ICO files
    paths = [
        os.path.join("nasds", "windows", "runner", "resources"),
        os.path.join("windows", "runner", "resources")
    ]
    
    # Create directories if they don't exist
    for path in paths:
        if not os.path.exists(path):
            print(f"Creating directory: {path}")
            os.makedirs(path, exist_ok=True)
    
    # Sizes for the icon (Windows standard sizes)
    sizes = [16, 32, 48, 64, 128, 256]
    
    # Create icons for each size
    icons = []
    for size in sizes:
        print(f"Creating {size}x{size} icon...")
        icons.append(create_icon(size, f"icon_{size}.png"))
    
    # Save as ICO files
    for path in paths:
        ico_path = os.path.join(path, "app_icon.ico")
        print(f"Saving ICO file to: {ico_path}")
        icons[0].save(
            ico_path,
            format="ICO",
            sizes=[(icon.width, icon.height) for icon in icons],
            append_images=icons[1:]
        )
        print(f"Successfully saved ICO file to: {ico_path}")
    
    print("Icon creation completed successfully!")
    print("\nNow try running: cd nasds && flutter run -d windows")

if __name__ == "__main__":
    main()
