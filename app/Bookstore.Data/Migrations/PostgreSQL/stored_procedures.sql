-- PostgreSQL equivalents of the SQL Server stored procedures
-- Originally: uspUpdateAuthorPersonalInfo, uspDeleteAuthor, uspGetProductData
-- Translated to PL/pgSQL for use with Npgsql / EF Core PostgreSQL provider

-- ============================================================
-- Procedure: usp_update_author_personal_info
-- Replaces:  [dbo].[uspUpdateAuthorPersonalInfo]
-- Performs an UPDATE on the "Author" table for personal info fields.
-- ============================================================
CREATE OR REPLACE PROCEDURE usp_update_author_personal_info(
    p_business_entity_id  INT,
    p_national_id_number  VARCHAR,
    p_birth_date          TIMESTAMP,
    p_marital_status      VARCHAR,
    p_gender              VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE "Author"
    SET
        "NationalIDNumber" = p_national_id_number,
        "BirthDate"        = p_birth_date,
        "MaritalStatus"    = p_marital_status,
        "Gender"           = p_gender,
        "ModifiedDate"     = NOW()
    WHERE "BusinessEntityID" = p_business_entity_id;
END;
$$;

-- ============================================================
-- Procedure: usp_delete_author
-- Replaces:  [dbo].[uspDeleteAuthor]
-- Performs a DELETE on the "Author" table by primary key.
-- ============================================================
CREATE OR REPLACE PROCEDURE usp_delete_author(
    p_business_entity_id INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM "Author"
    WHERE "BusinessEntityID" = p_business_entity_id;
END;
$$;

-- ============================================================
-- Function: usp_get_product_data
-- Replaces: [dbo].[uspGetProductData]
-- Returns all rows from the "Product" table as a set.
-- Called via: SELECT * FROM usp_get_product_data();
-- ============================================================
CREATE OR REPLACE FUNCTION usp_get_product_data()
RETURNS SETOF "Product"
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY SELECT * FROM "Product";
END;
$$;
