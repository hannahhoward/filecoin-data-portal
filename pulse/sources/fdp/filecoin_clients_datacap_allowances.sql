select
    allowance_id,
    client_id,
    allocator_id,
    height,
    height_at,
    message_cid,
    allowance_tibs,
    client_total_received_datacap_tibs,
    audit_trail,
    allowance_ttd,
    used_allowance,
    is_ldn_allowance,
    is_efil_allowance,
    is_from_autoverifier,
    retrieval_frequency,
    searched_by_proposal,
    issue_created_at,
    has_remaining_allowance,
    messaged_created_at,
    allocation_request_github_username,
    allocation_request_signing_address,
    allocation_request_id,
    allocation_request_type,
    allocation_request_created_at,
    allocation_request_updated_at,
    allocation_request_is_active,
    allocation_request_amount
from 'https://data.filecoindataportal.xyz/filecoin_clients_datacap_allowances.parquet'
