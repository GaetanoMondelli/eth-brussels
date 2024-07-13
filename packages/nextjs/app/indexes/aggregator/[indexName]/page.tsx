"use client";

import { useEffect, useState } from "react";
import { CheckCircleTwoTone } from "@ant-design/icons";
import { Line, Pie } from "react-chartjs-2";
import { Avatar, InputNumber, List, Modal, Popover, Select, Tag, Watermark } from "antd";
import { ArcElement, CategoryScale, Chart, LineElement, LinearScale, LogarithmicScale, PointElement } from "chart.js";
import * as young from "../../../mocks/young.json";
import * as category from "../../../mocks/category.json";
import type { NextPage } from "next";
import { useTargetNetwork } from "~~/hooks/scaffold-eth/useTargetNetwork";

Chart.register(CategoryScale);
Chart.register(LinearScale);
Chart.register(LogarithmicScale);
Chart.register(PointElement);
Chart.register(LineElement);
Chart.register(ArcElement);

const { Group } = Avatar;
const youngList = Object.values(young);
const categoryList = Object.values(category);

const colors = [
  "rgb(255, 99, 132)",
  "rgb(54, 162, 235)",
  "rgb(255, 205, 86)",
  "rgb(75, 192, 192)",
  "rgb(153, 102, 255)",
  "rgb(255, 159, 64)",
  "rgb(255, 159, 64)",
  "rgb(255, 99, 132)",
  "rgb(54, 162, 235)",
  "rgb(255, 205, 86)",
  "rgb(75, 192, 192)",
];

const IndexPage: NextPage = ({ params }: { params: { indexName: string } }) => {
  const [chartData, setChartData] = useState<any>();
  const [indexLimit, setIndexLimit] = useState(10);
  const [indexData, setIndexData] = useState<any>([]);
  const [equalWeighted, setEqualWeighted] = useState(false);
  const [isModalOpen, setIsModalOpen] = useState(false);

  const [etehreumTimeStamp, setEthereumTimeStamp] = useState<any>(new Date().toLocaleDateString());
  const [binanceTimeStamp, setBinanceTimeStamp] = useState<any>(new Date().toLocaleDateString());

  const { targetNetwork } = useTargetNetwork();

  useEffect(() => {
    // last 30 days for labels
    fetch(`/categories/${params.indexName}.json`)
      .then(response => response.json())
      .then(data => setIndexData(data))
      .catch(error => console.error("Error fetching data:", error));
    // console.log("indexData", indexData);
  }, []);

  const showModal = () => {
    setIsModalOpen(true);
  };

  const handleOk = () => {
    setIsModalOpen(false);
  };

  const handleCancel = () => {
    setIsModalOpen(false);
  };

  useEffect(() => {
    const today = new Date();
    const labels = Array.from({ length: 30 }, (_, i) => {
      const date = new Date(today);
      date.setDate(today.getDate() - i);
      return date.toLocaleDateString();
    });

    const data = indexData ? indexData.map((m: any) => m.current_price).slice(0, 30) : [];
    if (data.length < 30) {
      // push the same values from the start day by day
      let j = 0;
      for (let i = data.length; i < 30; i++) {
        data.push(data[j++]);
      }
    }

    setChartData({
      labels,
      datasets: [
        {
          label: "Meme Token Price",
          data,
          fill: false,
          borderColor: "rgb(75, 192, 192)",
          tension: 0.1,
        },
      ],
    });
  }, [indexData]);

  const isOnDiffChain = (symbol: string) => {
    const currentChain = targetNetwork.name === "Sepolia" ? "ETHEREUM" : targetNetwork.name;
    if (currentChain === "ETHEREUM") {
      return (
        youngList.find((y: any) => String(y.symbol).toLowerCase() === symbol.toLowerCase())?.networks?.[0].Name !==
        "ETHEREUM"
      );
    }
    return (
      youngList.find((y: any) => String(y.symbol).toLowerCase() === symbol.toLowerCase())?.networks?.[0].Name ===
      "ETHEREUM"
    );
  };

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
      content={targetNetwork.name}
      height={230}
      width={250}
    >
      <div className="text-center mt-8 p-10">
        <div
          style={{
            height: "250px",
            margin: "auto",
          }}
        >
          {chartData && (
            <Line
              width={1300}
              options={{
                scales: {
                  x: {
                    display: false,
                    grid: {
                      display: false,
                    },
                  },
                  y: {
                    display: false,
                    type: "logarithmic",
                    grid: {
                      display: false,
                    },
                  },
                },
              }}
              data={chartData}
            />
          )}
        </div>
        <br />
        <h1
          style={{
            fontSize: "3rem",
          }}
        >
          {params.indexName}
        </h1>
        <h2
          style={{
            fontSize: "1.3rem",
            marginBottom: "1rem",
          }}
        >
          {params.indexName + " "}
          <Popover
            content={
              <>
                <p>
                  Tags verfiied on <a href="https://www.reclaimprotocol.org/">coingecko.com</a>
                </p>
                <p>using reclaim protocol</p>
              </>
            }
            title={
              <>
                <p>
                  <span>TLS Verfied</span> <CheckCircleTwoTone twoToneColor="#52c41a" />
                </p>
              </>
            }
          >
            <CheckCircleTwoTone twoToneColor="#52c41a" />
          </Popover>
        </h2>
        <br />

        <p
          style={{
            width: "1000px",
            // border: "1px solid #ccc",
            // text justifies the text
            // center the text
            margin: "auto",
          }}
        >
          {/* Meme coins are coins that are created as a joke or meme. They are often created to make fun of the
          cryptocurrency industry or to make a quick buck. Some meme coins have gained popularity and have become
          valuable, while others have faded into obscurity. */}
          {categoryList.find((c: any) => c.id === params.indexName)?.content}
        </p>
        <br />
        <InputNumber
          style={{
            width: "50px",
            marginRight: "20px",
          }}
          label="Index Limit"
          min={3}
          max={indexData.length}
          value={indexLimit}
          onChange={(value: any) => setIndexLimit(value as number)}
        />

        <button
          style={{
            padding: "10px 20px",
            borderRadius: "5px",
            backgroundColor: "#1890ff",
            color: "white",
            border: "none",
            cursor: "pointer",
          }}
        >
          Update MarketCap and Liquidity
        </button>
        <br />
        <br />

        {indexData && (
          <List
            // className="demo-loadmore-list"
            itemLayout="horizontal"
            bordered
            style={{
              marginTop: "80px",
              minHeight: "400px",
              width: "1000px",
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
                actions={[
                  <a key="list-loadmore-edit">{"Rank #" + item.market_cap_rank}</a>,
                  <a key="list-loadmore-edit">{"$" + item.market_cap}</a>,
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
                    <>
                      {
                        <>
                          <Popover
                            // set the cursor to pointer

                            content={
                              isOnDiffChain(item.symbol) ? (
                                <p>
                                  Click to switch to{" "}
                                  {
                                    youngList.find(
                                      (y: any) => String(y.symbol).toLowerCase() === item.symbol.toLowerCase(),
                                    )?.networks?.[0].Name
                                  }
                                </p>
                              ) : (
                                ""
                              )
                            }
                          >
                            {item.name}
                            <Tag
                              style={{
                                cursor: "pointer",
                                marginLeft: "10px",
                                color: isOnDiffChain(item.symbol) ? "blue" : "green",
                              }}
                              onClick={() => {
                                console.log("clicked");
                              }}
                            >
                              {
                                youngList.find((y: any) => String(y.symbol).toLowerCase() === item.symbol.toLowerCase())
                                  ?.networks?.[0].Name
                              }
                            </Tag>
                          </Popover>
                        </>
                      }
                    </>
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
        )}
        {/* central button for launch an XTF Fund */}
        <br />
        <button
          style={{
            padding: "10px 20px",
            borderRadius: "5px",
            // backgroundColor: "#1890ff",
            backgroundColor: "#f56a00",
            color: "white",
            border: "none",
            cursor: "pointer",
          }}
          onClick={showModal}
        >
          Launch XTF Fund
        </button>
        <Modal
          width={1200}
          title={
            <h1
              style={{
                fontSize: "1.7rem",
              }}
            >
              Launch a new XTF Fund
            </h1>
          }
          open={isModalOpen}
          onOk={handleOk}
          onCancel={handleCancel}
          // hide cancel button
          footer={[
            <button
              key={1}
              style={{
                padding: "10px 20px",
                borderRadius: "5px",
                // backgroundColor: "#1890ff",
                backgroundColor: "#f56a00",
                color: "white",
                border: "none",
                cursor: "pointer",
              }}
              onClick={handleOk}
            >
              Create Fund
            </button>,
          ]}
        >
          <div
            style={{
              border: "1px solid #ccc",
              // center the text
              margin: "auto",
              width: "1000px",
              padding: "20px",
              marginTop: "30px",
            }}
          >
            <br />
            <div
              style={{
                width: "400px",
                margin: "auto",
              }}
            >
              <br />
              <div
                style={{
                  // width: "500px",
                  margin: "auto",
                  display: "flex",
                }}
              >
                <InputNumber
                  style={{
                    width: "150px",
                    marginRight: "20px",
                  }}
                  label="Index Limit"
                  min={3}
                  max={indexData.length}
                  value={indexLimit}
                  onChange={(value: any) => setIndexLimit(value as number)}
                />
                <InputNumber
                  style={{
                    width: "200px",
                    marginRight: "20px",
                  }}
                  formatter={value => `$ ${value}`.replace(/\B(?=(\d{3})+(?!\d))/g, ",")}
                  min={100}
                  defaultValue={1000}
                  max={10000}
                />
                <Select
                  defaultValue="cap_weighted"
                  style={{
                    width: "150px",
                  }}
                  onChange={(value: any) => {
                    if (value === "equal_weighted") {
                      setEqualWeighted(true);
                    } else {
                      setEqualWeighted(false);
                    }
                  }}
                >
                  <Select.Option value="cap_weighted">Cap Weighted</Select.Option>
                  <Select.Option value="equal_weighted">Equal Weighted</Select.Option>
                </Select>
              </div>
              <br />
              <Pie
                data={{
                  labels: indexData.map((m: any) => m.market_cap).slice(0, indexLimit),
                  datasets: [
                    {
                      label: "My First Dataset",
                      borderWidth: 2,
                      data: equalWeighted
                        ? Array(indexLimit).fill(1)
                        : indexData.map((m: any) => m.market_cap).slice(0, indexLimit),
                      backgroundColor: colors,
                      // hoverOffset: 4,
                    },
                  ],
                }}
              ></Pie>
            </div>
            <br />
            {/* print a custom legen made by small square of the color and name of asset next to it */}
            <div
              style={{
                width: "960px",
                margin: "auto",
              }}
            >
              {indexData.slice(0, indexLimit).map((m: any, i: number) => (
                <Group key={i} style={{ display: "inline-block", margin: "10px" }}>
                  <Avatar
                    style={{
                      backgroundColor: colors[i],
                      width: "20px",
                      height: "20px",
                      marginRight: "10px",
                    }}
                  ></Avatar>
                  <span>{m.name}</span>
                </Group>
              ))}
            </div>
          </div>
          <br />
        </Modal>
      </div>
    </Watermark>
  );
};

export default IndexPage;
