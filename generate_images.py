#!/usr/bin/env python3
"""
Image Generation Script for Kingsauna Website
Uses Google Imagen API to generate consistent, professional sauna images
"""

import os
import requests
import json
import time
from pathlib import Path

# API Configuration
API_KEY = "AIzaSyAPqvDpQf6bPpSBwmqipWv0HQd8oR7RYQQ"
IMAGES_DIR = Path("images")

# Ensure images directory exists
IMAGES_DIR.mkdir(exist_ok=True)

# Image generation specifications with consistent aesthetic
IMAGE_SPECS = [
    {
        "filename": "iglu-garden-installed.jpg",
        "prompt": "Professional photography of a modern triangular iglu sauna installed in a beautiful garden setting, natural wood exterior, large glass windows, surrounded by green plants and flowers, natural lighting, Scandinavian design, high quality product photography, 4K, clean composition",
        "alt": "Iglu pirtis sode"
    },
    {
        "filename": "barrel-classic.jpg",
        "prompt": "Professional photography of a classic wooden barrel sauna, natural pine or spruce wood, cylindrical shape, outdoor setting in natural environment, modern Scandinavian design, natural lighting, high quality product photography, 4K, architectural style",
        "alt": "Bačka lauko pirtis"
    },
    {
        "filename": "kvadratine-modern-dark.jpg",
        "prompt": "Professional photography of a modern square sauna with dark/black exterior, minimalist design, large glass windows, outdoor installation, contemporary architecture, natural lighting, high quality product photography, 4K, clean lines",
        "alt": "Kvadratinė lauko pirtis"
    },
    {
        "filename": "iglu-premium-glass.jpg",
        "prompt": "Professional photography of a modern triangular iglu sauna with large panoramic glass window, natural wood exterior, snow or natural setting, premium design, natural lighting, high quality product photography, 4K, architectural photography",
        "alt": "Trikampė iglu pirtis"
    },
    {
        "filename": "mobile-beach.jpg",
        "prompt": "Professional photography of a mobile sauna on a trailer at a beach, wooden barrel design, portable sauna, coastal setting, natural lighting, high quality product photography, 4K, outdoor lifestyle",
        "alt": "Mobili pirtis ant priekabos"
    },
    {
        "filename": "kubilas-wood.jpg",
        "prompt": "Professional photography of a wooden hot tub (kubilas) exterior, modern design, natural wood finish, outdoor setting, Scandinavian style, natural lighting, high quality product photography, 4K, clean composition",
        "alt": "Stiklo pluošto kubilas"
    },
    {
        "filename": "barrel-sauna-winter.jpeg",
        "prompt": "Professional photography of a wooden barrel sauna in winter, snow-covered ground, partially frozen lake in background, winter forest setting, warm light from sauna windows, natural lighting, high quality product photography, 4K, atmospheric winter scene",
        "alt": "Lauko pirtis žiemą"
    },
    {
        "filename": "barrel-large-window.jpg",
        "prompt": "Professional photography of a barrel sauna with large panoramic window, natural wood exterior, modern design, outdoor setting, natural lighting, high quality product photography, 4K, architectural detail",
        "alt": "Bačkos pirtis su dideliu langu"
    },
    {
        "filename": "barrel-exterior-chimney.jpg",
        "prompt": "Professional photography of a barrel sauna exterior with visible chimney, natural wood construction, outdoor installation, traditional design with modern elements, natural lighting, high quality product photography, 4K, architectural photography",
        "alt": "Bačkos pirtis su kaminu"
    },
    {
        "filename": "barrel-interior-window.jpg",
        "prompt": "Beautiful sauna interior with wooden benches, large window showing natural view outside, warm lighting, cozy atmosphere, natural wood interior, professional interior photography, 4K, inviting space",
        "alt": "Pirties vidus su langu"
    },
    {
        "filename": "iglu-terrace.jpg",
        "prompt": "Professional photography of an iglu sauna with small wooden terrace and steps, natural wood exterior, outdoor setting, modern Scandinavian design, natural lighting, high quality product photography, 4K, architectural style",
        "alt": "Iglu pirtis su terasa"
    },
    {
        "filename": "kvadratine-contrast.jpg",
        "prompt": "Professional photography of a square sauna with white trim accents, modern design, natural wood with white details, outdoor installation, contemporary architecture, natural lighting, high quality product photography, 4K, clean design",
        "alt": "Kvadratinė pirtis"
    },
    {
        "filename": "barrel-brown-hex.jpg",
        "prompt": "Professional photography of a brown barrel sauna with hexagonal shingles on roof, natural wood construction, outdoor setting, traditional design, natural lighting, high quality product photography, 4K, architectural detail",
        "alt": "Bačkos pirtis su šešiakampiais čerpėmis"
    },
    {
        "filename": "iglu-shingle-dark.jpg",
        "prompt": "Professional photography of an iglu sauna with dark shingle roof, natural wood walls, outdoor installation, modern Scandinavian design, natural lighting, high quality product photography, 4K, architectural photography",
        "alt": "Iglu pirtis su tamsiais čerpėmis"
    },
    {
        "filename": "modern-pod-saunas.jpg",
        "prompt": "Professional photography of modern pod-style saunas, contemporary design, natural wood exterior, outdoor setting, minimalist architecture, natural lighting, high quality product photography, 4K, modern lifestyle",
        "alt": "Namelis"
    },
    {
        "filename": "iglu-compact-green.jpg",
        "prompt": "Professional photography of a compact iglu sauna with green shingle roof, natural wood construction, outdoor setting, modern design, natural lighting, high quality product photography, 4K, architectural style",
        "alt": "Trikampės Iglu"
    },
    {
        "filename": "barrel-grey-winter.jpg",
        "prompt": "Professional photography of a grey barrel sauna in winter setting, snow-covered ground, winter atmosphere, natural lighting, high quality product photography, 4K, winter scene",
        "alt": "Grey barrel sauna winter"
    },
    {
        "filename": "barrel-interior-led.jpg",
        "prompt": "Beautiful sauna interior with LED lighting, wooden benches, modern design, warm ambient light, cozy atmosphere, professional interior photography, 4K, inviting space",
        "alt": "Sauna interior with LED"
    },
    {
        "filename": "barrel-mini-glass.jpg",
        "prompt": "Professional photography of a mini barrel sauna with full glass door, compact design, natural wood exterior, outdoor setting, modern design, natural lighting, high quality product photography, 4K, architectural detail",
        "alt": "Mini barrel with glass door"
    },
    {
        "filename": "sauna-hot-tub-combo.jpg",
        "prompt": "Professional photography of a sauna and hot tub combination, wooden sauna with adjacent hot tub, outdoor setting, modern design, natural lighting, high quality product photography, 4K, luxury lifestyle",
        "alt": "Sauna and hot tub combo"
    },
    {
        "filename": "square-interior-benches.jpg",
        "prompt": "Beautiful square sauna interior with wooden benches, warm lighting, natural wood interior, cozy atmosphere, professional interior photography, 4K, inviting space",
        "alt": "Square sauna interior"
    },
    {
        "filename": "square-modern-glass.jpg",
        "prompt": "Professional photography of a modern square sauna with large glass panels, contemporary design, natural wood and glass combination, outdoor setting, natural lighting, high quality product photography, 4K, architectural style",
        "alt": "Modern square sauna with glass"
    },
    {
        "filename": "triangle-iglu-interior.jpg",
        "prompt": "Beautiful triangular iglu sauna interior, wooden benches, warm lighting, natural wood interior, cozy atmosphere, professional interior photography, 4K, inviting space",
        "alt": "Iglu sauna interior"
    },
    {
        "filename": "kvadratine-brown.jpg",
        "prompt": "Professional photography of a brown square sauna, natural wood exterior, outdoor setting, modern design, natural lighting, high quality product photography, 4K, architectural style",
        "alt": "Brown square sauna"
    },
    {
        "filename": "kvadratine-minimal-black.jpg",
        "prompt": "Professional photography of a minimal black square sauna with large window, contemporary design, outdoor setting, modern architecture, natural lighting, high quality product photography, 4K, minimalist style",
        "alt": "Minimal black square sauna"
    },
    {
        "filename": "iglu-natural.jpg",
        "prompt": "Professional photography of a natural wood iglu sauna, front view, outdoor setting, Scandinavian design, natural lighting, high quality product photography, 4K, architectural photography",
        "alt": "Natural iglu sauna"
    },
    {
        "filename": "iglu-double-teal.jpg",
        "prompt": "Professional photography of a double iglu sauna with teal trim, natural wood construction, outdoor setting, modern design, natural lighting, high quality product photography, 4K, architectural style",
        "alt": "Double iglu with teal trim"
    },
    {
        "filename": "mobile-sauna-garden.jpg",
        "prompt": "Professional photography of a mobile sauna in a garden setting, wooden barrel design on trailer, natural environment, outdoor lifestyle, natural lighting, high quality product photography, 4K, garden installation",
        "alt": "Mobile sauna in garden"
    },
    {
        "filename": "modern-pod-saunas.jpg",
        "prompt": "Professional photography of modern pod-style saunas, contemporary design, natural wood exterior, outdoor setting, minimalist architecture, natural lighting, high quality product photography, 4K, modern lifestyle",
        "alt": "Modern pod saunas"
    },
    {
        "filename": "fir-wood.jpg",
        "prompt": "Close-up professional photography of fir wood texture, natural wood grain, high quality, detailed, natural lighting, 4K, texture detail",
        "alt": "Fir wood texture"
    },
    {
        "filename": "pine-wood.jpg",
        "prompt": "Close-up professional photography of pine wood texture, natural wood grain, high quality, detailed, natural lighting, 4K, texture detail",
        "alt": "Pine wood texture"
    },
    {
        "filename": "thermo-wood.jpg",
        "prompt": "Close-up professional photography of thermo-wood texture, treated wood grain, high quality, detailed, natural lighting, 4K, texture detail",
        "alt": "Thermo wood texture"
    },
    {
        "filename": "interior-wood.jpg",
        "prompt": "Beautiful sauna interior wood detail, natural wood grain, warm lighting, professional interior photography, 4K, texture detail",
        "alt": "Interior wood detail"
    }
]

def generate_image_with_imagen(prompt, output_path):
    """
    Generate image using Google Imagen API via REST endpoint
    """
    try:
        import google.generativeai as genai
        
        # Configure the API
        genai.configure(api_key=API_KEY)
        
        # Try to use Imagen model if available
        # Note: Google's image generation might be through Vertex AI or different endpoint
        try:
            # Try using the generative model for image generation
            model = genai.GenerativeModel('imagen-3')
            response = model.generate_content(
                prompt,
                generation_config={
                    "temperature": 0.4,
                    "top_p": 0.95,
                    "top_k": 40,
                }
            )
            
            # Save the image
            if hasattr(response, 'images') and response.images:
                image_data = response.images[0]
                with open(output_path, 'wb') as f:
                    f.write(image_data)
                return True
        except Exception as e:
            print(f"   ⚠️  Error with Imagen model: {str(e)}")
            
        # Fallback: Try REST API approach
        return generate_image_via_rest(prompt, output_path)
        
    except ImportError:
        print(f"   ⚠️  google-generativeai not installed, trying REST API")
        return generate_image_via_rest(prompt, output_path)
    except Exception as e:
        print(f"   ⚠️  Error: {str(e)}")
        return False

def generate_image_via_rest(prompt, output_path):
    """
    Generate image using REST API call to Google's image generation endpoint
    """
    try:
        # Google's image generation REST endpoint (if available)
        # This might need to be adjusted based on actual API
        url = f"https://generativelanguage.googleapis.com/v1beta/models/imagen-3:generateImage?key={API_KEY}"
        
        payload = {
            "prompt": prompt,
            "number_of_images": 1,
            "aspect_ratio": "4:3"
        }
        
        headers = {
            "Content-Type": "application/json"
        }
        
        response = requests.post(url, json=payload, headers=headers, timeout=60)
        
        if response.status_code == 200:
            data = response.json()
            # Extract image data (format depends on API response)
            if 'images' in data and len(data['images']) > 0:
                image_url = data['images'][0].get('url') or data['images'][0].get('base64')
                
                if image_url:
                    if image_url.startswith('http'):
                        # Download from URL
                        img_response = requests.get(image_url, timeout=30)
                        if img_response.status_code == 200:
                            with open(output_path, 'wb') as f:
                                f.write(img_response.content)
                            return True
                    else:
                        # Base64 encoded
                        import base64
                        image_data = base64.b64decode(image_url)
                        with open(output_path, 'wb') as f:
                            f.write(image_data)
                        return True
        else:
            print(f"   ⚠️  API returned status {response.status_code}: {response.text[:200]}")
            return False
            
    except Exception as e:
        print(f"   ⚠️  REST API error: {str(e)}")
        return False

def generate_image_with_alternative(prompt, output_path):
    """
    Alternative: Use a web-based image generation API or service
    """
    # Try using a different approach - could use DALL-E, Stable Diffusion API, etc.
    print(f"📝 Would generate: {output_path.name}")
    print(f"   Prompt: {prompt[:150]}...")
    return False

def main():
    print("🎨 Kingsauna Image Generation Script")
    print("=" * 50)
    print(f"📁 Images directory: {IMAGES_DIR.absolute()}")
    print(f"📊 Total images to generate: {len(IMAGE_SPECS)}")
    print()
    
    # Skip logo and vidaus sauna interior as requested
    skip_files = ["logo.png", "interior-sauna-modern.jpg"]
    
    generated = 0
    skipped = 0
    
    for spec in IMAGE_SPECS:
        filename = spec["filename"]
        output_path = IMAGES_DIR / filename
        
        # Skip if file should not be regenerated
        if filename in skip_files:
            print(f"⏭️  Skipping {filename} (preserved)")
            skipped += 1
            continue
        
        # Skip if already exists (optional - remove if you want to regenerate)
        if output_path.exists():
            print(f"✓ Already exists: {filename}")
            continue
        
        print(f"\n🖼️  Generating: {filename}")
        print(f"   Prompt: {spec['prompt'][:100]}...")
        
        # Try to generate image
        # Note: Actual implementation depends on available API
        success = generate_image_with_imagen(spec["prompt"], output_path)
        
        if success:
            generated += 1
            print(f"   ✓ Generated successfully")
        else:
            print(f"   ⚠️  Generation method not yet implemented")
            print(f"   💡 You may need to use Vertex AI or another image generation service")
    
    print("\n" + "=" * 50)
    print(f"✅ Complete!")
    print(f"   Generated: {generated}")
    print(f"   Skipped: {skipped}")
    print(f"   Total: {len(IMAGE_SPECS)}")

if __name__ == "__main__":
    main()
