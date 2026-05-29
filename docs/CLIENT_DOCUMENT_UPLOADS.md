# Client KYC document uploads

The **Client** model is the customer record. Each client may have exactly three Active Storage attachments:

| Attachment | Purpose |
|------------|---------|
| `ine_document` | INE (government ID) |
| `tax_document` | Comprobante fiscal |
| `proof_of_address_document` | Comprobante de domicilio |

## API

### Create / update (multipart)

Set `client[require_documents]=true` to require all three files on that request.

```http
POST /clients
Authorization: Bearer <token>
Content-Type: multipart/form-data

client[full_name]=Juan Pérez
client[email]=juan@example.com
client[require_documents]=true
client[ine_document]=@ine.pdf
client[tax_document]=@tax.pdf
client[proof_of_address_document]=@address.jpg
```

```http
PATCH /clients/1
Authorization: Bearer <token>
Content-Type: multipart/form-data

client[tax_document]=@updated_tax.pdf
```

Allowed types: **PDF, JPEG, PNG**. Max size: **10 MB** per file.

### Download (authenticated)

```http
GET /clients/1/documents/ine
GET /clients/1/documents/tax_document
GET /clients/1/documents/proof_of_address
Authorization: Bearer <token>
```

Requires `ClientPolicy#show?` (staff or seller). Returns redirect to a signed blob URL.

### Verification status (optional)

Columns: `ine_verification_status`, `tax_document_verification_status`, `proof_of_address_verification_status`  
Values: `pending`, `approved`, `rejected` (staff may set via JSON on update).

Re-uploading a file resets that document's status to `pending`.

## Authorization

Pundit `ClientPolicy`: create/update/destroy — **admin** and **super_user** only.  
Show/index — staff and seller. Document download uses `show?`.

## Optional next steps

- Background virus scan (ClamAV + Active Storage analyzer)
- ActiveJob to run Marcel / byte inspection after attach
- Direct upload with `ActiveStorage::DirectUploadsController` for large files
