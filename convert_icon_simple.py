"""
Convert SVG to ICO file using a simpler approach with svglib and reportlab.
"""
import os
import io
from PIL import Image
from svglib.svglib import svg2rlg
from reportlab.graphics import renderPM

def svg_to_png(svg_file, output_size):
    """Convert SVG to PNG with specified size."""
    drawing = svg2rlg(svg_file)
    
    # Calculate scale factor
    original_width = drawing.width
    original_height = drawing.height
    scale = min(output_size / original_width, output_size / original_height)
    
    # Scale the drawing
    drawing.width = output_size
    drawing.height = output_size
    drawing.scale(scale, scale)
    
    # Render to PNG
    png_data = renderPM.drawToString(drawing, fmt="PNG")
    return Image.open(io.BytesIO(png_data))

def main():
    # Paths
    script_dir = os.path.dirname(os.path.abspath(__file__))
    svg_path = os.path.join(script_dir, "nasds", "windows", "runner", "resources", "nasds_icon_simple.svg")
    ico_path = os.path.join(script_dir, "nasds", "windows", "runner", "resources", "app_icon.ico")
    
    # Create directory if it doesn't exist
    os.makedirs(os.path.dirname(ico_path), exist_ok=True)
    
    # Check if SVG file exists
    if not os.path.exists(svg_path):
        print(f"SVG file not found at: {svg_path}")
        # Check if it exists in the root windows directory
        alt_svg_path = os.path.join(script_dir, "windows", "runner", "resources", "nasds_icon_simple.svg")
        if os.path.exists(alt_svg_path):
            print(f"Found SVG at alternative location: {alt_svg_path}")
            svg_path = alt_svg_path
        else:
            print("SVG file not found. Please check the file path.")
            return
    
    print(f"Converting SVG: {svg_path}")
    
    # Sizes for the icon (Windows standard sizes)
    sizes = [16, 32, 48, 64, 128, 256]
    
    # Convert SVG to multiple PNG sizes
    images = []
    for size in sizes:
        print(f"Converting to {size}x{size}...")
        try:
            img = svg_to_png(svg_path, size)
            images.append(img)
        except Exception as e:
            print(f"Error converting size {size}x{size}: {e}")
    
    if not images:
        print("No images were converted. Check for errors above.")
        return
    
    # Save as ICO
    print(f"Saving ICO file to: {ico_path}")
    try:
        # The first image is used as the base, and we save all images as frames
        images[0].save(
            ico_path,
            format="ICO",
            sizes=[(img.width, img.height) for img in images],
            append_images=images[1:]
        )
        print("Conversion completed successfully!")
        
        # Also save to the root windows directory if it exists
        alt_ico_path = os.path.join(script_dir, "windows", "runner", "resources", "app_icon.ico")
        if os.path.exists(os.path.dirname(alt_ico_path)):
            print(f"Also saving to alternative location: {alt_ico_path}")
            images[0].save(
                alt_ico_path,
                format="ICO",
                sizes=[(img.width, img.height) for img in images],
                append_images=images[1:]
            )
    except Exception as e:
        print(f"Error saving ICO file: {e}")

if __name__ == "__main__":
    main()
    print("\nNow try running: cd nasds && flutter run -d windows")
