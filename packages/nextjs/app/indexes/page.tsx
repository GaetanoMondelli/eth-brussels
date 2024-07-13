"use client";

import { useEffect, useState } from "react";
import Image from "next/image";
import * as category from "../mocks/category.json";
import * as market from "../mocks/market.json";
import * as young from "../mocks/young.json";
import { InfoCircleOutlined } from "@ant-design/icons";
import { Avatar, Card, Col, Divider, InputNumber, List, Modal, Row, Select, Switch, Tag } from "antd";
import { Watermark } from "antd";
import { Steps } from "antd";
import type { NextPage } from "next";
import { useWriteContract } from "wagmi";
import { useTargetNetwork } from "~~/hooks/scaffold-eth/useTargetNetwork";
import { getAllContracts } from "~~/utils/scaffold-eth/contractsData";

const { Group } = Avatar;
const youngList = Object.values(young);

const Indexes: NextPage = () => {
  const [showAll, setShowAll] = useState(false);
  const [lastUpdate, setLastUpdate] = useState("13 June 2024");
  const [modalState, setModalState] = useState(0);
  const indexData = Object.values(market);
  const indexLimit = 20;

  const contractName = "IndexAggregator";
  const { targetNetwork } = useTargetNetwork();

  const isModalVisible = modalState > 0;

  const contractsData = getAllContracts();

  const { writeContract } = useWriteContract();

  const currentChain = targetNetwork.name === "Sepolia" ? "ETHEREUM" : targetNetwork.name;

  return (
    <Watermark
      zIndex={-9}
      style={
        // take the whole screen in the behind all the elements
        {
          position: "absolute",
          top: 0,
          left: 0,
          width: "100%",
          minHeight: "100%",
        }
      }
      content={"Sepolia"}
      height={230}
      width={250}
    >
      <div
        style={{
          marginLeft: "70px",
          marginRight: "70px",
        }}
        className="text-center mt-8 p-10"
      >
        <h1
          style={{
            fontSize: "2rem",
            marginBottom: "1rem",
          }}
        >
          Indexes
        </h1>

        <h1>Price Oralces & OnChain aggregators</h1>
        <h2>
          <Group maxCount={3} size="large" maxStyle={{ color: "#f56a00", backgroundColor: "#fde3cf" }}>
            <Avatar
              style={{
                width: "30px",
                height: "30px",
                marginRight: "10px",
              }}
              src="data:image/jpeg;base64,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"
            ></Avatar>
            <Avatar
              style={{
                width: "30px",
                height: "30px",
                marginRight: "10px",
              }}
              src="data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wCEAAkGBwgHBgkIBwgKCgkLDRYPDQwMDRsUFRAWIB0iIiAdHx8kKDQsJCYxJx8fLT0tMTU3Ojo6Iys/RD84QzQ5OjcBCgoKDQwNGg8PGjclHyU3Nzc3Nzc3Nzc3Nzc3Nzc3Nzc3Nzc3Nzc3Nzc3Nzc3Nzc3Nzc3Nzc3Nzc3Nzc3Nzc3N//AABEIAL0AyAMBIgACEQEDEQH/xAAbAAEBAQEBAQEBAAAAAAAAAAAABgcFAwIEAf/EADwQAQABAwEDBQ4FAwUAAAAAAAACAQMEBQYRkiE1VGGyEhMUFTE2QVFTc3SCk9EWInKxwSMzNDJScZGh/8QAGgEBAAMBAQEAAAAAAAAAAAAAAAMEBQYCAf/EADARAQABAgIHBgYDAQAAAAAAAAABAgMEEQUSFBUzUXEhMTI0UqFhgbHB0eETQfAi/9oADAMBAAIRAxEAPwDcQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABzta1expON3y7+a7L+3bpXllX7dbPM3VMzMyJ37t+dJS9EZVpSlPVSiG7fpt9n9qGLx9vDzq98tUGS+FZPSLvHU8KyekXeOqHa45Ke+afR7taGS+FZPSLvHU8KyekXeOptccjfNPo92tCN2EvXbuVlUuXJzpSFN3dSrX0rJZt169Os1MNf8A57cXIjIAe04AAAAAAAAAAAAAA5eu61Y0mxvlunfnT+nb3+Xrr1PPaDXbOk2u4juuZU6fkh6uuvUzzJyL2VfneyJ1ncnXfWVVa9f1OynvZeP0hFn/AIt+L6PrNy7+dkTyMmdZ3Jen1dVOp4AoTObm5mapzkAfHwABV7Af5WX7uP7rVFbAf5WX7uP7rVpYfhw6nRnlqfn9QBO0AAAAAAAAAAAABw9o9ft6XbrZs7p5cqckfRDrr9ncZvtd5w5fydiKG/XNFGcKGkb9diznR3zOTlX71zIuyu3p1ncnXfKUq8tXwDMctM59sj6jCcqb4xlWnVR8rvYLmm98RXsxSWqNerJYwmH2i5qZ5IfvVz2c+E71c9nPha6LOyfFqbmj1+37ZF3q57OfCd6ueznwtdDZPibmj1+37RewUJRysvuo1p/Tj5ada0HzO5C3Slbk4xpX/dXcs26NSnJqYaxGHtRRnnk+h5eFY/t7XHQ8Kx/b2uOj1nCbWp5vUeXhWP7e1x0f2F+zOXcwuwlX1UlSpnD7rRzegD6+gAAAAAAADN9rvOHL+TsRaQzfa7zhy/k7EVbFeCOrK0xwI6/aXHAZ7mxd7Bc03viK9mKEXewXNN74ivZisYbiNLRXmY6SpQGi6cAAS+33N+N77+KqhL7fc343vv4qiv8ADlTx/lq0OAy3JDt7G8/2P0z7NXEdvY3n+x+mfZqkteOFjCcejrDRQGq7EAAAAAAAAZvtd5w5fydiLSGb7XecOX8nYirYrwR1ZWmOBHX7S44DPc2LvYLmm98RXsxQi72C5pvfEV7MVjDcRpaK8zHSVKA0XTgACX2+5vxvffxVUJfb7m/G99/FUV/hyp4/y1aHAZbkh29jef7H6Z9mriO3sbz/AGP0z7NUlrxwsYTj0dYaKA1XYgAAAAAAACD2m0rPydcyb1jEu3Lcu53SjHkr+WlF4I7luLkZSrYrDU4iiKKpy7c2X+I9U6Df4TxHqnQb/C1AQ7JTzUNz2vVLL/EeqdBv8Kn2Xv2tHwbmPqk44t6V2s4wu8lax3Upv/8AKqlCbe87Wfh6dqTzVbizGvDxcw1OAj+aic5+Kq8eaX06xxHjzS+nWOJmA8bXVyQ74u+mGn+PNL6dY4jx5pfTrHEzANrq5G+Lvphp/jzS+nWOJPbZ6jh5mFYhi5Fu7KN3fWka791N1UiPNeIqqpyyRXtJ3LtuaJpjtAFdmDubGQlLXbUoxrWkYSrKtKeTkc/StNyNUyqWMePXOdfJCnrq0fSdMx9LxqWcenLXlnOvlnVYsWpqq1v6hp6Owldy5FzuiH7QGi6YAAAAAAAAAAAAQm3vO1n4enaku0Jt7ztZ+Hp2pK+J4bN0r5aesJoBnOYAAAAH79H0rI1XJ71Zp3MKf67lackaffqfeiaPf1bI7mH5LMf7l2tOSnVTraNgYVjAxo4+NDuYR/7rX1161izYmvtnuaWBwE3516/D9Xxpun4+m4sbGNHdSnLKVfLKvrq/WDQiIiModLTTFMatPcAPr0AAAAAAAAAAAAJPazRs/UdQtXsOzScI2aRrXu6U5d9a+mvWrB4roiuMpQ4ixTfo1Ku5nH4W1jotPqx+5+FtY6LT6sfu0cQ7LQobosc59vwzj8Lax0Wn1Y/c/C2sdFp9WP3aOGy0G6LHOfb8M4/C2sdFp9WP3fowdktQu5MY5kKWLPllKk6Sr/xTcvwjC0PtOicPE59v++TxxMWzh48LGNCkLcaclKPYFmOxpxERGUAA+gAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP/9k="
            ></Avatar>
            <Avatar
              style={{
                width: "30px",
                height: "30px",
                marginRight: "10px",
              }}
              src="data:image/png;base64,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"
            ></Avatar>
          </Group>
          Powered by <b>Flare</b>, <b>Chronicles Protocol</b> <b>Pyth Network</b> Price Feeds <br></br>
          <Avatar
            style={{
              width: "30px",
              height: "30px",
              marginRight: "10px",
            }}
            src="data:image/png;base64,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"
          ></Avatar>
          Powered by <b>Uniswap</b> Liquidity Feeds{" "}
          <InfoCircleOutlined
            onClick={() => {
              setModalState(3);
            }}
            twoToneColor="#52c41a"
          />
        </h2>
        <Switch
          checkedChildren="Show All Tokens"
          unCheckedChildren="Show Categories"
          checked={showAll}
          onChange={setShowAll}
          style={{
            marginBottom: "1rem",
          }}
        />
        <br />
        <br />

        {!showAll && (
          <Row gutter={130}>
            {category
              // get the first 10 categories
              .slice(0, 16)
              .filter(c => c.content !== "")
              .map(c => (
                <Col span={8} key={c.name}>
                  <Card
                    title={
                      <a
                        // remove also ( )
                        // href={`/indexes/${c.name.toLowerCase().replace(/\(|\)/g, "").replace(/\s/g, "-")}`}
                        href={`/indexes/aggregator/${c.id}`}
                        // target="_blank"
                        rel="noopener noreferrer"
                      >
                        {c.name}
                      </a>
                    }
                    bordered={false}
                    style={{
                      height: "200px",
                      overflow: "hidden",
                    }}
                    extra={
                      <Group maxCount={3} size="large" maxStyle={{ color: "#f56a00", backgroundColor: "#fde3cf" }}>
                        {c.top_3_coins.map((coin: any) => (
                          <Avatar key={coin} src={coin} />
                        ))}
                      </Group>
                    }
                  >
                    <p
                      style={{
                        display: "-webkit-box",
                        WebkitBoxOrient: "vertical",
                        overflow: "hidden",
                        textOverflow: "ellipsis",
                        lineHeight: "1.2em",
                        height: "6em",
                        WebkitLineClamp: 5,
                        whiteSpace: "pre-wrap",
                        textAlign: "left",
                      }}
                    >
                      {c.content}
                    </p>
                  </Card>
                  <br />
                </Col>
              ))}
          </Row>
        )}
        {showAll && (
          <>
            <b>Last Price Sample</b>: {lastUpdate}
            <br></br>
            <b>Time Window</b>: 30 days
            <br></br>
            <b>Bribe</b>: 0.05 sepETH
            <br></br>
            <b>Contract Reserve:</b> 1 sepETH (200 days left)
            <br></br>
            <br></br>
            <div
              style={{
                display: "flex",
                // center the buttons
                justifyContent: "center",
                gap: "10px",
              }}
            >
              <button
                style={{
                  marginTop: "10px",
                  paddingRight: "5px",
                  paddingLeft: "5px",
                  borderRadius: "10px",
                  color: "white",
                  backgroundColor: "#f56a00",
                }}
                onClick={() => {
                  setLastUpdate(new Date().toLocaleString());
                }}
              >
                Collect Prices (Bribe)
              </button>

              {currentChain === "ETHEREUM" ? (
                <button
                  style={{
                    marginTop: "10px",
                    padding: "3px",
                    paddingRight: "7px",
                    paddingLeft: "7px",
                    borderRadius: "10px",
                    color: "white",
                    // green
                    backgroundColor: "#52c41a",
                  }}
                  onClick={async () => {
                    await writeContract({
                      address: contractsData[contractName].address,
                      functionName: "setChainId",
                      abi: contractsData[contractName].abi,
                      args: [targetNetwork.id, targetNetwork.id],
                    });
                  }}
                >
                  Persist Index
                </button>
              ) : (
                <button
                  style={{
                    marginTop: "10px",
                    padding: "3px",
                    paddingRight: "7px",
                    paddingLeft: "7px",
                    borderRadius: "10px",
                    color: "white",
                    // blue
                    backgroundColor: "#1890ff",
                  }}
                  onClick={async () => {
                    console.log("communicating to mainchain");
                    console.log(contractsData[contractName].address);
                    console.log(contractsData[contractName].abi);
                    await writeContract({
                      address: contractsData[contractName].address,
                      functionName: "setChainId",
                      abi: contractsData[contractName].abi,
                      args: ["11155111", "11155111"],
                    });
                    // setLastUpdate(new Date().toLocaleString());
                  }}
                >
                  Communicate to Mainchain
                </button>
              )}
            </div>
            <br></br>
            <br></br>
            <List
              // className="demo-loadmore-list"
              itemLayout="horizontal"
              bordered
              style={{
                marginTop: "80px",
                minHeight: "400px",
                width: "800px",
                margin: "auto",
              }}
              dataSource={
                // meme is not an array, so we need to convert it to an array
                Object.keys(indexData)
                  .map((k: any) => indexData[k])
                  .slice(0, indexLimit)
              }
              renderItem={item => (
                <List.Item
                  style={{
                    background: "#f4f8ff",
                  }}
                  actions={[
                    <a key="list-loadmore-edit">{"Rank #" + item.market_cap_rank}</a>,
                    <a key="list-loadmore-more">{"Lqdty: " + Math.random().toFixed(2) + "P"}</a>,
                  ]}
                >
                  <List.Item.Meta
                    avatar={
                      <Avatar
                        style={{
                          width: "50px",
                          height: "50px",
                        }}
                        src={item.image}
                      />
                    }
                    title={
                      <a href="https://ant.design">
                        {
                          <>
                            {item.name}
                            <Tag
                              style={{
                                marginLeft: "10px",
                              }}
                            >
                              {youngList.find((y: any) => String(y.symbol).toLowerCase() === item.symbol.toLowerCase())
                                ?.networks?.[0].Name || "Wrapped Ethereum (Sepolia)"}
                            </Tag>
                          </>
                        }
                      </a>
                    }
                    description={
                      <span>
                        {youngList.find((y: any) => String(y.symbol).toLowerCase() === item.symbol.toLowerCase())
                          ?.descriptions?.en !== undefined
                          ? youngList
                              .find((y: any) => String(y.symbol).toLowerCase() === item.symbol.toLowerCase())
                              ?.descriptions?.en?.slice(0, 100) + "..."
                          : "No description available"}
                      </span>
                    }
                  />
                </List.Item>
              )}
            />
          </>
        )}
      </div>
      <Divider></Divider>

      <Modal
        width={1500}
        // title="ChainLink Data Feeds"
        visible={isModalVisible}
        onOk={() => setModalState(0)}
        onCancel={() => setModalState(0)}
        footer={null}
      >
        <Image
          width={1400}
          height={1200}
          src={
            modalState === 1
              ? "/images/tls_oracle.png"
              : modalState === 2
                ? "/images/attestation.png"
                : "/images/index_aggr.png"
          }
          style={{
            display: "flex",
            justifyContent: "flex-end",
            alignItems: "center",
            borderRadius: "5px",
            boxShadow: "0px 1px 6px rgba(0, 0, 0, 0.25)",
          }}
          alt="Available on OpenSea"
        />
        <br />
      </Modal>
    </Watermark>
  );
};

export default Indexes;
