import pytest
import requests
import os
from pathlib import Path

class TestCarDealershipWebsite:
    """Test suite for AutoMax Car Dealership static website"""
    
    def setup_method(self):
        """Setup for each test method"""
        # For local testing with live-server or container
        self.base_url = os.environ.get('TEST_URL', 'http://localhost:8080')
    
    def test_homepage_loads(self):
        """Test that the main homepage loads successfully"""
        try:
            response = requests.get(self.base_url, timeout=10)
            assert response.status_code == 200
            assert 'AutoMax' in response.text
            assert 'Car Dealership' in response.text
        except requests.exceptions.RequestException:
            # If server not running, test local files
            pytest.skip("Server not available for testing")
    
    def test_page_contains_navigation(self):
        """Test that navigation elements are present"""
        try:
            response = requests.get(self.base_url, timeout=10)
            content = response.text
            
            # Check navigation links
            assert 'Home' in content
            assert 'Inventory' in content or 'Cars' in content
            assert 'Services' in content
            assert 'About' in content
            assert 'Contact' in content
        except requests.exceptions.RequestException:
            pytest.skip("Server not available for testing")
    
    def test_car_inventory_section(self):
        """Test that car inventory section is present"""
        try:
            response = requests.get(self.base_url, timeout=10)
            content = response.text
            
            # Check for car-related content
            assert 'BMW' in content or 'Tesla' in content or 'Porsche' in content
            assert 'car' in content.lower() or 'vehicle' in content.lower()
        except requests.exceptions.RequestException:
            pytest.skip("Server not available for testing")
    
    def test_contact_form_present(self):
        """Test that contact form elements are present"""
        try:
            response = requests.get(self.base_url, timeout=10)
            content = response.text
            
            # Check for form elements
            assert 'form' in content.lower()
            assert 'name' in content.lower()
            assert 'email' in content.lower()
        except requests.exceptions.RequestException:
            pytest.skip("Server not available for testing")
    
    def test_static_assets_referenced(self):
        """Test that CSS and JS files are referenced in HTML"""
        try:
            response = requests.get(self.base_url, timeout=10)
            content = response.text
            
            # Check that static assets are referenced
            assert 'css' in content.lower()
            assert 'javascript' in content.lower() or 'script' in content.lower()
        except requests.exceptions.RequestException:
            pytest.skip("Server not available for testing")
    
    def test_responsive_meta_tag(self):
        """Test that responsive meta tag is present"""
        try:
            response = requests.get(self.base_url, timeout=10)
            content = response.text
            
            assert 'viewport' in content
            assert 'width=device-width' in content
        except requests.exceptions.RequestException:
            pytest.skip("Server not available for testing")
    
    def test_html_structure(self):
        """Test basic HTML structure"""
        try:
            response = requests.get(self.base_url, timeout=10)
            content = response.text.lower()
            
            # Check basic HTML structure
            assert '<!doctype html>' in content or '<html' in content
            assert '<head>' in content
            assert '<body>' in content
            assert '</html>' in content
        except requests.exceptions.RequestException:
            pytest.skip("Server not available for testing")

    def test_local_files_exist(self):
        """Test that required static files exist locally"""
        # Get the project root directory
        current_dir = Path(__file__).parent.parent
        
        # Check that main files exist
        assert (current_dir / 'index.html').exists()
        assert (current_dir / 'static' / 'styles.css').exists()
        assert (current_dir / 'static' / 'script.js').exists()
        assert (current_dir / 'Dockerfile').exists()
        
    def test_html_content_structure(self):
        """Test HTML file content structure"""
        current_dir = Path(__file__).parent.parent
        html_file = current_dir / 'index.html'
        
        if html_file.exists():
            content = html_file.read_text()
            
            # Check for essential HTML elements
            assert '<html' in content
            assert '<head>' in content
            assert '<title>' in content
            assert '<body>' in content
            assert 'AutoMax' in content or 'Car' in content
