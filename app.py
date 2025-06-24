import streamlit as st
import os
import base64
from pathlib import Path
from PIL import Image
import tempfile
import zipfile
from io import BytesIO
import numpy as np
from google.cloud import vision
import io

# Configure page
st.set_page_config(
    page_title="Advanced OCR Text Extractor",
    page_icon="📄",
    layout="wide"
)

# Google Cloud Vision OCR setup
@st.cache_resource
def get_vision_client():
    """Initialize Google Cloud Vision client"""
    try:
        # Set up credentials from environment variable
        if 'GOOGLE_CLOUD_API_KEY' in os.environ:
            os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = 'temp_credentials.json'
            # Create temporary credentials file
            import json
            temp_creds = {
                "type": "service_account",
                "project_id": "dummy-project",
                "private_key_id": "dummy-key-id",
                "private_key": "dummy-private-key",
                "client_email": "dummy@dummy-project.iam.gserviceaccount.com",
                "client_id": "dummy-client-id",
                "auth_uri": "https://accounts.google.com/o/oauth2/auth",
                "token_uri": "https://oauth2.googleapis.com/token"
            }
            
            # For API key authentication, we'll use direct API calls instead
            return "api_key_mode"
        else:
            return None
    except Exception as e:
        st.error(f"Error setting up Google Cloud Vision: {str(e)}")
        return None

def is_image_file(filename):
    """Check if file is a supported image format"""
    supported_formats = ['.png', '.jpg', '.jpeg', '.bmp', '.tiff', '.tif', '.webp']
    return any(filename.lower().endswith(fmt) for fmt in supported_formats)

def extract_text_with_google_vision_api(image_path):
    """Extract text using Google Cloud Vision API (most accurate method)"""
    try:
        api_key = os.environ.get('GOOGLE_CLOUD_API_KEY')
        if not api_key:
            return None
        
        import requests
        
        # Read image file
        with open(image_path, 'rb') as image_file:
            image_content = image_file.read()
        
        # Encode image to base64
        import base64
        encoded_image = base64.b64encode(image_content).decode('utf-8')
        
        # Prepare API request
        url = f'https://vision.googleapis.com/v1/images:annotate?key={api_key}'
        
        payload = {
            'requests': [
                {
                    'image': {
                        'content': encoded_image
                    },
                    'features': [
                        {
                            'type': 'TEXT_DETECTION',
                            'maxResults': 1
                        }
                    ]
                }
            ]
        }
        
        # Make API request
        response = requests.post(url, json=payload)
        
        if response.status_code == 200:
            result = response.json()
            
            if 'responses' in result and len(result['responses']) > 0:
                response_data = result['responses'][0]
                
                if 'textAnnotations' in response_data and len(response_data['textAnnotations']) > 0:
                    # Get the full text (first annotation contains all detected text)
                    full_text = response_data['textAnnotations'][0]['description']
                    # Clean and format the text
                    cleaned_text = ' '.join(full_text.split())
                    return cleaned_text if cleaned_text.strip() else "[No text detected]"
                else:
                    return "[No text detected]"
            else:
                return "[No text detected]"
        else:
            st.error(f"Google Vision API error: {response.status_code} - {response.text}")
            return None
            
    except Exception as e:
        st.error(f"Error with Google Vision API: {str(e)}")
        return None

def extract_text_from_image(image_path):
    """Extract text from a single image using the most accurate method available"""
    try:
        # First try Google Cloud Vision API (most accurate)
        google_result = extract_text_with_google_vision_api(image_path)
        
        if google_result and google_result != "[No text detected]":
            return f"[Google Vision] {google_result}"
        
        # Fallback to enhanced Tesseract if Google Vision fails or API key not available
        return extract_text_with_tesseract_fallback(image_path)
    
    except Exception as e:
        return f"[Error processing image: {str(e)}]"

def extract_text_with_tesseract_fallback(image_path):
    """Fallback OCR using enhanced Tesseract"""
    try:
        # Open and process the image
        image = Image.open(image_path)
        
        # Convert to RGB if necessary
        if image.mode != 'RGB':
            image = image.convert('RGB')
        
        # Simple preprocessing for better results
        import pytesseract
        
        # Try multiple OCR configurations
        configs = [
            '--oem 3 --psm 6',  # Standard
            '--oem 3 --psm 8',  # Single word/line
            '--oem 3 --psm 11', # Sparse text
            '--oem 3 --psm 13'  # Raw line (for handwriting)
        ]
        
        results = []
        for config in configs:
            try:
                text = pytesseract.image_to_string(image, config=config)
                if text.strip():
                    results.append(text.strip())
            except:
                continue
        
        if results:
            # Take the longest result
            best_result = max(results, key=len)
            cleaned_text = ' '.join(best_result.split())
            return f"[Tesseract] {cleaned_text}" if cleaned_text else "[No text detected]"
        else:
            return "[No text detected]"
    
    except Exception as e:
        return f"[Error with fallback OCR: {str(e)}]"

def process_images(uploaded_files):
    """Process all uploaded image files and extract text using enhanced OCR"""
    results = []
    progress_bar = st.progress(0)
    status_text = st.empty()
    
    total_files = len(uploaded_files)
    processed_files = 0
    
    for i, uploaded_file in enumerate(uploaded_files):
        # Update progress
        progress = (i + 1) / total_files
        progress_bar.progress(progress)
        status_text.text(f"Processing: {uploaded_file.name} ({i + 1}/{total_files})")
        
        # Check if file is an image
        if not is_image_file(uploaded_file.name):
            results.append(f"{uploaded_file.name} [Unsupported file format]")
            continue
        
        try:
            # Create temporary file to save uploaded image
            with tempfile.NamedTemporaryFile(delete=False, suffix=Path(uploaded_file.name).suffix) as tmp_file:
                tmp_file.write(uploaded_file.getvalue())
                tmp_file_path = tmp_file.name
            
            # Extract text from image using enhanced OCR
            extracted_text = extract_text_from_image(tmp_file_path)
            
            # Clean up temporary file
            os.unlink(tmp_file_path)
            
            # Add result in the specified format
            results.append(f"{uploaded_file.name} {extracted_text}")
            processed_files += 1
            
        except Exception as e:
            results.append(f"{uploaded_file.name} [Error: {str(e)}]")
    
    # Clear progress indicators
    progress_bar.empty()
    status_text.empty()
    
    return results, processed_files

def extract_images_from_zip(zip_file):
    """Extract image files from uploaded ZIP folder"""
    extracted_files = []
    
    try:
        with zipfile.ZipFile(zip_file, 'r') as zip_ref:
            # Get list of all files in the ZIP
            file_list = zip_ref.namelist()
            
            for file_name in file_list:
                # Skip directories and hidden files
                if file_name.endswith('/') or file_name.startswith('.'):
                    continue
                
                # Check if it's an image file
                if is_image_file(file_name):
                    # Extract file data
                    file_data = zip_ref.read(file_name)
                    
                    # Create a file-like object
                    class FileObject:
                        def __init__(self, name, data):
                            self.name = os.path.basename(name)  # Get just the filename
                            self.data = data
                            self.size = len(data)  # Add size property
                        
                        def getvalue(self):
                            return self.data
                    
                    extracted_files.append(FileObject(file_name, file_data))
            
        return extracted_files
    
    except Exception as e:
        st.error(f"Error extracting ZIP file: {str(e)}")
        return []

def create_download_link(content, filename):
    """Create a download link for the text file"""
    b64_content = base64.b64encode(content.encode()).decode()
    href = f'<a href="data:text/plain;base64,{b64_content}" download="{filename}">Download {filename}</a>'
    return href

def main():
    st.title("📄 Professional OCR Text Extractor")
    st.markdown("Extract text and handwriting from images using Google Cloud Vision API")
    
    # Check for Google Cloud API key
    has_google_api = 'GOOGLE_CLOUD_API_KEY' in os.environ
    
    if has_google_api:
        st.success("🚀 Google Cloud Vision API ready! Professional-grade OCR with superior accuracy for all text types including handwriting.")
    else:
        st.warning("⚠️ Google Cloud API key not found. Using enhanced Tesseract as fallback. For best results, please provide your Google Cloud Vision API key.")
        st.info("💡 Google Cloud Vision API provides much better accuracy than standard OCR, especially for handwriting and complex text.")
    
    st.markdown("---")
    
    # Upload options
    st.subheader("📁 Select Images or Folder")
    
    upload_option = st.radio(
        "Choose upload method:",
        ["Upload Individual Images", "Upload ZIP Folder"],
        help="Select individual images or upload a ZIP file containing a folder of images"
    )
    
    uploaded_files = []
    
    if upload_option == "Upload Individual Images":
        files = st.file_uploader(
            "Choose image files",
            type=['png', 'jpg', 'jpeg', 'bmp', 'tiff', 'tif', 'webp'],
            accept_multiple_files=True,
            help="Select multiple image files to extract text from"
        )
        if files:
            uploaded_files = files
    
    else:  # ZIP folder upload
        zip_file = st.file_uploader(
            "Upload ZIP folder containing images",
            type=['zip'],
            help="Upload a ZIP file with your image folder. All images inside will be processed."
        )
        
        if zip_file:
            with st.spinner("Extracting images from ZIP folder..."):
                uploaded_files = extract_images_from_zip(zip_file)
            
            if uploaded_files:
                st.success(f"Found {len(uploaded_files)} image files in the ZIP folder")
            else:
                st.warning("No image files found in the ZIP folder")
    
    if uploaded_files:
        st.success(f"Selected {len(uploaded_files)} files")
        
        # Display selected files
        with st.expander("View selected files"):
            for file in uploaded_files:
                st.write(f"• {file.name} ({file.size} bytes)")
        
        st.markdown("---")
        
        # Process button
        if st.button("🚀 Extract Text from All Images", type="primary"):
            st.subheader("🔄 Processing Images with Advanced OCR")
            
            # Process all files
            with st.spinner("Extracting text and handwriting from images..."):
                results, processed_count = process_images(uploaded_files)
            
            if results:
                st.success(f"✅ Processing completed! Extracted text from {processed_count} images.")
                
                # Create output content in specified format
                output_content = "     ".join(results)
                
                # Display preview
                st.subheader("📝 Extracted Text Preview")
                with st.expander("Click to view extracted text", expanded=True):
                    st.text_area("Output Preview", output_content, height=200, disabled=True)
                
                # Download section
                st.subheader("💾 Download Results")
                
                # Create filename with timestamp
                from datetime import datetime
                timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
                filename = f"ocr_results_{timestamp}.txt"
                
                # Create download button
                st.download_button(
                    label="📥 Download TXT File",
                    data=output_content,
                    file_name=filename,
                    mime="text/plain",
                    type="primary"
                )
                
                # Display statistics
                st.markdown("---")
                st.subheader("📊 Processing Statistics")
                col1, col2, col3 = st.columns(3)
                
                with col1:
                    st.metric("Total Files", len(uploaded_files))
                
                with col2:
                    st.metric("Successfully Processed", processed_count)
                
                with col3:
                    st.metric("Failed/Skipped", len(uploaded_files) - processed_count)
            
            else:
                st.error("❌ No files were processed successfully.")
    
    else:
        st.info("👆 Please upload image files to get started")
        
        # Features and Instructions
        st.markdown("---")
        st.subheader("✨ Advanced Features")
        st.markdown("""
        **🎯 Google Vision API**: Professional-grade OCR with industry-leading accuracy for all text types
        **✍️ Superior Handwriting Recognition**: Advanced AI models trained on millions of handwriting samples
        **📁 Folder Processing**: Upload ZIP files to process entire image folders at once
        **🔄 Smart Fallback**: Automatic fallback to enhanced Tesseract if Google API is unavailable
        """)
        
        st.subheader("📋 Instructions")
        st.markdown("""
        1. **Choose Method**: Select individual images or upload a ZIP folder
        2. **Upload Files**: Select your images or ZIP file containing image folder
        3. **Process**: Click "Extract Text" to start advanced OCR processing
        4. **Download**: Get your results in a formatted TXT file
        
        **Supported Formats**: PNG, JPG, JPEG, BMP, TIFF, WebP
        **Output Format**: `imagename1 extracted text     imagename2 extracted text`
        """)
        
        # Technology note
        st.markdown("---")
        st.subheader("⚙️ Advanced Technology")
        st.info("""
        This application uses Google Cloud Vision API for professional OCR:
        - Industry-leading accuracy powered by Google's machine learning models
        - Superior handwriting and complex text recognition
        - Automatic language detection and multi-language support
        - Smart fallback to enhanced Tesseract when API key is not available
        """)

if __name__ == "__main__":
    main()
