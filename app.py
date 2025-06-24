import streamlit as st
import os
import base64
from pathlib import Path
from PIL import Image
import pytesseract
import tempfile
import zipfile
from io import BytesIO

# Configure page
st.set_page_config(
    page_title="OCR Text Extractor",
    page_icon="📄",
    layout="wide"
)

def is_image_file(filename):
    """Check if file is a supported image format"""
    supported_formats = ['.png', '.jpg', '.jpeg', '.bmp', '.tiff', '.tif', '.webp']
    return any(filename.lower().endswith(fmt) for fmt in supported_formats)

def extract_text_from_image(image_path):
    """Extract text from a single image using OCR"""
    try:
        # Open and process the image
        image = Image.open(image_path)
        
        # Convert to RGB if necessary (for PNG with transparency, etc.)
        if image.mode != 'RGB':
            image = image.convert('RGB')
        
        # Extract text using pytesseract
        extracted_text = pytesseract.image_to_string(image, lang='eng')
        
        # Clean up the text (remove excessive whitespace and newlines)
        cleaned_text = ' '.join(extracted_text.split())
        
        return cleaned_text if cleaned_text.strip() else "[No text detected]"
    
    except Exception as e:
        return f"[Error processing image: {str(e)}]"

def process_folder(uploaded_files):
    """Process all uploaded image files and extract text"""
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
            
            # Extract text from image
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

def create_download_link(content, filename):
    """Create a download link for the text file"""
    b64_content = base64.b64encode(content.encode()).decode()
    href = f'<a href="data:text/plain;base64,{b64_content}" download="{filename}">Download {filename}</a>'
    return href

def main():
    st.title("📄 OCR Text Extractor")
    st.markdown("Upload images to extract text using OCR technology")
    
    st.markdown("---")
    
    # File uploader
    st.subheader("📁 Select Images")
    uploaded_files = st.file_uploader(
        "Choose image files",
        type=['png', 'jpg', 'jpeg', 'bmp', 'tiff', 'tif', 'webp'],
        accept_multiple_files=True,
        help="Select multiple image files to extract text from"
    )
    
    if uploaded_files:
        st.success(f"Selected {len(uploaded_files)} files")
        
        # Display selected files
        with st.expander("View selected files"):
            for file in uploaded_files:
                st.write(f"• {file.name} ({file.size} bytes)")
        
        st.markdown("---")
        
        # Process button
        if st.button("🚀 Extract Text from All Images", type="primary"):
            st.subheader("🔄 Processing Images")
            
            # Process all files
            with st.spinner("Extracting text from images..."):
                results, processed_count = process_folder(uploaded_files)
            
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
        
        # Instructions
        st.markdown("---")
        st.subheader("📋 Instructions")
        st.markdown("""
        1. **Select Images**: Click the file uploader above to select multiple image files
        2. **Supported Formats**: PNG, JPG, JPEG, BMP, TIFF, WebP
        3. **Process**: Click the "Extract Text" button to start OCR processing
        4. **Download**: Get your results in a formatted TXT file
        
        **Output Format**: `imagename1 extracted text     imagename2 extracted text`
        """)
        
        # Requirements note
        st.markdown("---")
        st.subheader("⚙️ Requirements")
        st.info("""
        This application uses Tesseract OCR for text extraction. Make sure you have:
        - Tesseract OCR installed on your system
        - Python packages: streamlit, pytesseract, Pillow
        """)

if __name__ == "__main__":
    main()
