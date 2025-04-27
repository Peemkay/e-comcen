"""
Convert SVG to ICO file with verbose output.
"""
import os
import sys
import traceback
from PIL import Image
from svglib.svglib import svg2rlg
from reportlab.graphics import renderPM

def main():
    print("Starting SVG to ICO conversion script...")
    print(f"Current working directory: {os.getcwd()}")
    
    # Paths
    script_dir = os.path.dirname(os.path.abspath(__file__))
    print(f"Script directory: {script_dir}")
    
    # Check both possible locations for the SVG file
    svg_paths = [
        os.path.join(script_dir, "nasds", "windows", "runner", "resources", "nasds_icon_simple.svg"),
        os.path.join(script_dir, "windows", "runner", "resources", "nasds_icon_simple.svg")
    ]
    
    svg_path = None
    for path in svg_paths:
        print(f"Checking for SVG at: {path}")
        if os.path.exists(path):
            svg_path = path
            print(f"Found SVG file at: {path}")
            break
    
    if not svg_path:
        print("SVG file not found in any of the expected locations!")
        return
    
    # Determine where to save the ICO file
    ico_paths = [
        os.path.join(script_dir, "nasds", "windows", "runner", "resources", "app_icon.ico"),
        os.path.join(script_dir, "windows", "runner", "resources", "app_icon.ico")
    ]
    
    for ico_path in ico_paths:
        ico_dir = os.path.dirname(ico_path)
        print(f"Checking directory: {ico_dir}")
        if not os.path.exists(ico_dir):
            print(f"Creating directory: {ico_dir}")
            os.makedirs(ico_dir, exist_ok=True)
    
    print(f"Converting SVG: {svg_path}")
    
    # Sizes for the icon (Windows standard sizes)
    sizes = [16, 32, 48, 64, 128, 256]
    
    try:
        # Convert SVG to RLG drawing
        print("Converting SVG to ReportLab drawing...")
        drawing = svg2rlg(svg_path)
        
        # Convert to multiple sizes
        images = []
        for size in sizes:
            print(f"Converting to {size}x{size}...")
            
            # Calculate scale factor
            original_width = drawing.width
            original_height = drawing.height
            scale = min(size / original_width, size / original_height)
            
            # Create a copy of the drawing for this size
            import copy
            sized_drawing = copy.deepcopy(drawing)
            
            # Scale the drawing
            sized_drawing.width = size
            sized_drawing.height = size
            sized_drawing.scale(scale, scale)
            
            # Render to PNG
            png_data = renderPM.drawToString(sized_drawing, fmt="PNG")
            img = Image.open(io.BytesIO(png_data))
            
            # Ensure the image is the correct size
            if img.width != size or img.height != size:
                print(f"  Resizing from {img.width}x{img.height} to {size}x{size}")
                img = img.resize((size, size), Image.LANCZOS)
            
            images.append(img)
            print(f"  Successfully converted to {size}x{size}")
        
        # Save as ICO to both possible locations
        for ico_path in ico_paths:
            print(f"Saving ICO file to: {ico_path}")
            images[0].save(
                ico_path,
                format="ICO",
                sizes=[(img.width, img.height) for img in images],
                append_images=images[1:]
            )
            print(f"Successfully saved ICO file to: {ico_path}")
        
        print("Conversion completed successfully!")
        
    except Exception as e:
        print(f"Error during conversion: {e}")
        traceback.print_exc()

if __name__ == "__main__":
    import io  # Import here to avoid issues with the traceback
    main()
    print("\nNow try running: cd nasds && flutter run -d windows")
