set define off
set feedback on

prompt Seeding Oracle source objects for migration smoke test...

begin
  execute immediate 'drop synonym omm_cust_syn';
exception
  when others then
    if sqlcode != -1434 then raise; end if;
end;
/

begin
  execute immediate 'drop package omm_order_pkg';
exception
  when others then
    if sqlcode != -4043 then raise; end if;
end;
/

begin
  execute immediate 'drop trigger omm_orders_bi';
exception
  when others then
    if sqlcode != -4080 then raise; end if;
end;
/

begin
  execute immediate 'drop view omm_orders_v';
exception
  when others then
    if sqlcode != -942 then raise; end if;
end;
/

begin
  execute immediate 'drop index omm_idx_cust_lower_name';
exception
  when others then
    if sqlcode != -1418 then raise; end if;
end;
/

begin
  execute immediate 'drop sequence omm_order_seq';
exception
  when others then
    if sqlcode != -2289 then raise; end if;
end;
/

begin
  execute immediate 'drop table omm_customer_kv purge';
exception
  when others then
    if sqlcode != -942 then raise; end if;
end;
/

begin
  execute immediate 'drop table omm_sales_part purge';
exception
  when others then
    if sqlcode != -942 then raise; end if;
end;
/

begin
  execute immediate 'drop table omm_orders purge';
exception
  when others then
    if sqlcode != -942 then raise; end if;
end;
/

begin
  execute immediate 'drop table omm_customers purge';
exception
  when others then
    if sqlcode != -942 then raise; end if;
end;
/

create table omm_customers (
  customer_id      number primary key,
  customer_name    varchar2(120) not null,
  email            varchar2(255),
  signup_date      date,
  credit_limit     number,
  profile_doc      clob,
  created_at       timestamp default systimestamp
);

create table omm_orders (
  order_id         number primary key,
  customer_id      number not null,
  order_date       date not null,
  order_amount     number(12,2) not null,
  order_status     varchar2(30),
  constraint fk_omm_orders_customer
    foreign key (customer_id) references omm_customers(customer_id)
);

create sequence omm_order_seq start with 100 increment by 1 nocache;

create or replace trigger omm_orders_bi
before insert on omm_orders
for each row
begin
  if :new.order_id is null then
    :new.order_id := omm_order_seq.nextval;
  end if;
end;
/

create or replace package omm_order_pkg as
  procedure add_order(
    p_customer_id in number,
    p_order_date  in date,
    p_amount      in number,
    p_status      in varchar2
  );
end omm_order_pkg;
/

create or replace package body omm_order_pkg as
  procedure add_order(
    p_customer_id in number,
    p_order_date  in date,
    p_amount      in number,
    p_status      in varchar2
  ) is
  begin
    insert into omm_orders(order_id, customer_id, order_date, order_amount, order_status)
    values (null, p_customer_id, p_order_date, p_amount, p_status);
  end add_order;
end omm_order_pkg;
/

create view omm_orders_v as
select
  o.order_id,
  c.customer_name,
  o.order_date,
  o.order_amount,
  o.order_status
from omm_orders o
join omm_customers c
  on c.customer_id = o.customer_id;

create synonym omm_cust_syn for omm_customers;

create index omm_idx_cust_lower_name
  on omm_customers (lower(customer_name));

create table omm_sales_part (
  sale_id          number,
  sale_date        date not null,
  sale_amount      number(12,2),
  remarks          varchar2(200)
)
partition by range (sale_date) (
  partition p_2024 values less than (date '2025-01-01'),
  partition p_2025 values less than (date '2026-01-01'),
  partition p_max  values less than (maxvalue)
);

create table omm_customer_kv (
  customer_id      number not null,
  attr_name        varchar2(60) not null,
  attr_value       varchar2(200),
  constraint pk_omm_customer_kv primary key (customer_id, attr_name)
)
organization index;

insert into omm_customers (customer_id, customer_name, email, signup_date, credit_limit, profile_doc)
values (1, 'Acme Corp', 'ops@acme.example', date '2025-01-05', 500000, 'Primary enterprise account');

insert into omm_customers (customer_id, customer_name, email, signup_date, credit_limit, profile_doc)
values (2, 'Blue Retail', 'finance@blue.example', date '2025-02-10', 175000, 'Retail segment');

begin
  omm_order_pkg.add_order(1, date '2025-02-15', 2100.50, 'NEW');
  omm_order_pkg.add_order(2, date '2025-02-16', 500.00, 'SHIPPED');
end;
/

insert into omm_sales_part (sale_id, sale_date, sale_amount, remarks)
values (1, date '2025-03-01', 1200, 'partition smoke row');

insert into omm_customer_kv (customer_id, attr_name, attr_value)
values (1, 'tier', 'gold');

commit;

begin
  dbms_stats.gather_table_stats(user, 'OMM_CUSTOMERS');
  dbms_stats.gather_table_stats(user, 'OMM_ORDERS');
  dbms_stats.gather_table_stats(user, 'OMM_SALES_PART');
  dbms_stats.gather_table_stats(user, 'OMM_CUSTOMER_KV');
end;
/

prompt Seed complete.

