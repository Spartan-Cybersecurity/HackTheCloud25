#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <curl/curl.h>
#include <openssl/sha.h>
#include <openssl/hmac.h>
#include <openssl/evp.h>

#define MAX_BUFFER_SIZE 4096
#define AWS_REGION "us-east-1"
#define SERVICE_NAME "s3"

// Configuration structure
typedef struct {
    char* memory;
    size_t size;
} MemoryStruct;

// Medical system configuration - Service credentials (injected at build time)
#ifndef AWS_ACCESS_KEY_ID
#define AWS_ACCESS_KEY_ID "PLACEHOLDER_ACCESS_KEY"
#endif

#ifndef AWS_SECRET_ACCESS_KEY  
#define AWS_SECRET_ACCESS_KEY "PLACEHOLDER_SECRET_KEY"
#endif

// Obfuscated credential storage
static const char* get_access_key() {
    return AWS_ACCESS_KEY_ID;
}

// Split secret key into segments for reverse engineering challenge
static char* get_secret_key_part1() {
    static char part1[32];
    strncpy(part1, AWS_SECRET_ACCESS_KEY, 12);
    part1[12] = '\0';
    return part1;
}

static char* get_secret_key_part2() {
    static char part2[32];
    strncpy(part2, AWS_SECRET_ACCESS_KEY + 12, 12);
    part2[12] = '\0';
    return part2;
}

static char* get_secret_key_part3() {
    static char part3[32];
    strcpy(part3, AWS_SECRET_ACCESS_KEY + 24);
    return part3;
}

// Medical export configuration
static const char* bucket_name_template = "ctf-25-medical-exporter-records-%s";
static const char* export_endpoints[] = {
    "exports/patient_manifest.json",
    "exports/cardiovascular_patients.json", 
    "exports/lab_results.json"
};

// Callback function for libcurl
static size_t WriteMemoryCallback(void *contents, size_t size, size_t nmemb, void *userp) {
    size_t realsize = size * nmemb;
    MemoryStruct *mem = (MemoryStruct *)userp;
    
    char *ptr = realloc(mem->memory, mem->size + realsize + 1);
    if (!ptr) {
        printf("Not enough memory (realloc returned NULL)\n");
        return 0;
    }
    
    mem->memory = ptr;
    memcpy(&(mem->memory[mem->size]), contents, realsize);
    mem->size += realsize;
    mem->memory[mem->size] = 0;
    
    return realsize;
}

// Function to reconstruct complete secret key
char* get_service_auth_token() {
    static char complete_secret[256];
    memset(complete_secret, 0, sizeof(complete_secret));
    
    // Reconstruct secret key from parts for authentication
    strcat(complete_secret, get_secret_key_part1());
    strcat(complete_secret, get_secret_key_part2());  
    strcat(complete_secret, get_secret_key_part3());
    
    return complete_secret;
}

// AWS Signature V4 Implementation
void bytes_to_hex(const unsigned char* bytes, int len, char* hex_output) {
    for (int i = 0; i < len; i++) {
        sprintf(hex_output + (i * 2), "%02x", bytes[i]);
    }
    hex_output[len * 2] = '\0';
}

void sha256_hash(const char* data, unsigned char* hash) {
    SHA256_CTX sha256;
    SHA256_Init(&sha256);
    SHA256_Update(&sha256, data, strlen(data));
    SHA256_Final(hash, &sha256);
}

void hmac_sha256(const char* key, int key_len, const char* data, unsigned char* output) {
    HMAC(EVP_sha256(), key, key_len, (unsigned char*)data, strlen(data), output, NULL);
}

// Generate AWS Signature V4 Authorization Header
char* generate_aws_auth_header(const char* method, const char* bucket, const char* object_key, const char* timestamp) {
    static char auth_header[1024];
    
    // Simplified AWS Signature V4 implementation  
    char canonical_request[1024];
    snprintf(canonical_request, sizeof(canonical_request), 
        "%s\n/%s\n\nhost:%s.s3.amazonaws.com\nx-amz-content-sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\nx-amz-date:%s\n\nhost;x-amz-content-sha256;x-amz-date\ne3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
        method, object_key, bucket, timestamp);
    
    unsigned char canonical_hash[32];
    sha256_hash(canonical_request, canonical_hash);
    
    char canonical_hex[65];
    bytes_to_hex(canonical_hash, 32, canonical_hex);
    
    // Create string to sign
    char string_to_sign[512];
    char datestamp[9];
    strncpy(datestamp, timestamp, 8);
    datestamp[8] = '\0';
    
    snprintf(string_to_sign, sizeof(string_to_sign),
        "AWS4-HMAC-SHA256\n%s\n%s/%s/s3/aws4_request\n%s",
        timestamp, datestamp, AWS_REGION, canonical_hex);
    
    // Generate signing key (simplified)
    char secret_key_full[256];
    snprintf(secret_key_full, sizeof(secret_key_full), "AWS4%s", get_service_auth_token());
    
    unsigned char date_key[32];
    hmac_sha256(secret_key_full, strlen(secret_key_full), datestamp, date_key);
    
    unsigned char date_region_key[32];
    hmac_sha256((char*)date_key, 32, AWS_REGION, date_region_key);
    
    unsigned char date_region_service_key[32];
    hmac_sha256((char*)date_region_key, 32, "s3", date_region_service_key);
    
    unsigned char signing_key[32];
    hmac_sha256((char*)date_region_service_key, 32, "aws4_request", signing_key);
    
    // Generate signature
    unsigned char signature_bytes[32];
    hmac_sha256((char*)signing_key, 32, string_to_sign, signature_bytes);
    
    char signature_hex[65];
    bytes_to_hex(signature_bytes, 32, signature_hex);
    
    // Build authorization header
    snprintf(auth_header, sizeof(auth_header),
        "AWS4-HMAC-SHA256 Credential=%s/%s/%s/s3/aws4_request, SignedHeaders=host;x-amz-content-sha256;x-amz-date, Signature=%s",
        get_access_key(), datestamp, AWS_REGION, signature_hex);
    
    return auth_header;
}

// Function to display banner
void display_banner() {
    printf("\n");
    printf("╔══════════════════════════════════════════════════════════════╗\n");
    printf("║                    MediCloudX Data Exporter                  ║\n");
    printf("║                  Patient Records Export Tool                 ║\n");
    printf("║                        Version 2.1.3                        ║\n");
    printf("╠══════════════════════════════════════════════════════════════╣\n");
    printf("║  Authorized personnel only - Healthcare data export utility  ║\n");
    printf("║  Compliant with HIPAA regulations and security protocols     ║\n");
    printf("╚══════════════════════════════════════════════════════════════╝\n");
    printf("\n");
}

// Function to show available exports
void show_export_options() {
    printf("Available Data Exports:\n");
    printf("  [1] Patient Manifest (Overview)\n");
    printf("  [2] Cardiovascular Patient Records\n");
    printf("  [3] Laboratory Results\n");
    printf("  [0] Exit\n\n");
}

// Function to download from S3 with real AWS authentication
int download_from_s3(const char* bucket_suffix, const char* object_key) {
    CURL *curl;
    CURLcode res;
    MemoryStruct chunk;
    
    chunk.memory = malloc(1);  // Will be grown as needed by realloc
    chunk.size = 0;    // No data at this point
    
    curl_global_init(CURL_GLOBAL_DEFAULT);
    curl = curl_easy_init();
    if (!curl) {
        printf("Error: Failed to initialize CURL\n");
        return -1;
    }
    
    // Generate timestamp for AWS authentication
    time_t now = time(NULL);
    struct tm *utc_tm = gmtime(&now);
    char timestamp[17];
    strftime(timestamp, sizeof(timestamp), "%Y%m%dT%H%M%SZ", utc_tm);
    
    // Construct full bucket name
    char full_bucket_name[256];
    snprintf(full_bucket_name, sizeof(full_bucket_name), "ctf-25-medical-exporter-records-%s", bucket_suffix);
    
    // Construct S3 URL
    char s3_url[512];
    snprintf(s3_url, sizeof(s3_url), "https://%s.s3.amazonaws.com/%s", full_bucket_name, object_key);
    
    printf("Connecting to medical records database...\n");
    printf("Authenticating with healthcare service account...\n");
    
    // Generate AWS Signature V4 authorization header
    char* auth_header_content = generate_aws_auth_header("GET", full_bucket_name, object_key, timestamp);
    
    // Set up HTTP headers for AWS authentication
    struct curl_slist *headers = NULL;
    
    char auth_header[1024];
    snprintf(auth_header, sizeof(auth_header), "Authorization: %s", auth_header_content);
    
    char date_header[64];
    snprintf(date_header, sizeof(date_header), "x-amz-date: %s", timestamp);
    
    char host_header[256];
    snprintf(host_header, sizeof(host_header), "Host: %s.s3.amazonaws.com", full_bucket_name);
    
    char content_sha256_header[128];
    snprintf(content_sha256_header, sizeof(content_sha256_header), "x-amz-content-sha256: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855");
    
    headers = curl_slist_append(headers, auth_header);
    headers = curl_slist_append(headers, date_header);
    headers = curl_slist_append(headers, host_header);
    headers = curl_slist_append(headers, content_sha256_header);
    
    // Configure curl for S3 request
    curl_easy_setopt(curl, CURLOPT_URL, s3_url);
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, WriteMemoryCallback);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, (void *)&chunk);
    curl_easy_setopt(curl, CURLOPT_USERAGENT, "MediCloudX-Exporter/2.1.3");
    curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers);
    curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1L);
    curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, 1L);
    curl_easy_setopt(curl, CURLOPT_SSL_VERIFYHOST, 2L);
    
    // Perform the request
    res = curl_easy_perform(curl);
    
    if (res != CURLE_OK) {
        printf("Error: Download failed - %s\n", curl_easy_strerror(res));
    } else {
        long response_code;
        curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &response_code);
        
        if (response_code == 200) {
            printf("Successfully retrieved data from S3.\n");
            printf("\n--- Export Data ---\n");
            printf("%s\n", chunk.memory ? chunk.memory : "No data received");
            printf("--- End of Export ---\n\n");
        } else {
            printf("Error: HTTP %ld response from S3\n", response_code);
            if (chunk.memory) {
                printf("Response: %s\n", chunk.memory);
            }
        }
    }
    
    // Cleanup
    if (chunk.memory) {
        free(chunk.memory);
    }
    
    curl_slist_free_all(headers);
    curl_easy_cleanup(curl);
    curl_global_cleanup();
    
    return (res == CURLE_OK) ? 0 : -1;
}

// Main function
int main(int argc, char *argv[]) {
    display_banner();
    
    // Initialize curl
    curl_global_init(CURL_GLOBAL_DEFAULT);
    
    if (argc == 2 && strcmp(argv[1], "--version") == 0) {
        printf("MediCloudX Data Exporter v2.1.3\n");
        printf("Build: Release\n");
        printf("AWS SDK Integration: Embedded\n");
        printf("Security: HIPAA Compliant\n");
        curl_global_cleanup();
        return 0;
    }
    
    if (argc == 3 && strcmp(argv[1], "--bucket") == 0) {
        printf("Using custom bucket suffix: %s\n", argv[2]);
        
        int choice;
        show_export_options();
        printf("Select export option: ");
        scanf("%d", &choice);
        
        if (choice >= 1 && choice <= 3) {
            char bucket_name[256];
            snprintf(bucket_name, sizeof(bucket_name), "ctf-25-medical-exporter-records-%s", argv[2]);
            
            printf("Accessing medical records from: %s\n", bucket_name);
            download_from_s3(argv[2], export_endpoints[choice - 1]);
        } else if (choice == 0) {
            printf("Export cancelled.\n");
        } else {
            printf("Invalid selection.\n");
        }
        
        curl_global_cleanup();
        return 0;
    }
    
    printf("Usage:\n");
    printf("  %s --bucket <bucket_suffix>     Export medical records\n", argv[0]);
    printf("  %s --version                    Show version information\n", argv[0]);
    printf("\n");
    printf("Example:\n");
    printf("  %s --bucket a1b2c3d4\n", argv[0]);
    printf("\n");
    printf("For support contact: support@medicloudx.com\n");
    
    curl_global_cleanup();
    return 0;
}
